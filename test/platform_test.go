package test

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"io"
	"net"
	"net/http"
	"strings"
	"testing"
	"time"
)

const (
	traefikDomain   = "hashistack.test"
	traefikHTTPS    = "127.0.0.1:19443"
	pebbleCA        = "fixtures/stack/pebble.minica.pem"
	dnsProviderPath = "/bin/true"
)

func clientVia(address string, roots *x509.CertPool) *http.Client {
	dialer := &net.Dialer{Timeout: 5 * time.Second}
	return &http.Client{
		Timeout: 10 * time.Second,
		CheckRedirect: func(*http.Request, []*http.Request) error {
			return http.ErrUseLastResponse
		},
		Transport: &http.Transport{
			DialContext: func(ctx context.Context, network, _ string) (net.Conn, error) {
				return dialer.DialContext(ctx, network, address)
			},
			TLSClientConfig:   &tls.Config{RootCAs: roots, InsecureSkipVerify: roots == nil},
			DisableKeepAlives: true,
		},
	}
}

func get(t *testing.T, client *http.Client, url string) (int, string, *x509.Certificate) {
	t.Helper()
	request, err := http.NewRequestWithContext(t.Context(), http.MethodGet, url, nil)
	if err != nil {
		t.Fatal(err)
	}
	response, err := client.Do(request)
	if err != nil {
		return 0, "", nil
	}
	defer response.Body.Close()
	body, err := io.ReadAll(response.Body)
	if err != nil {
		return 0, "", nil
	}
	var cert *x509.Certificate
	if response.TLS != nil && len(response.TLS.PeerCertificates) > 0 {
		cert = response.TLS.PeerCertificates[0]
	}
	return response.StatusCode, strings.TrimSpace(string(body)), cert
}

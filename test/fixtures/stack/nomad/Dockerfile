FROM mirror.gcr.io/hashicorp/nomad:2.0.7 AS nomad

FROM mirror.gcr.io/library/docker:28.5-dind AS docker

FROM mirror.gcr.io/library/debian:13-slim
ARG TARGETARCH
ARG CNI_VERSION=1.9.1
RUN apt-get update \
 && apt-get install -y --no-install-recommends busybox ca-certificates curl dnsmasq-base iproute2 iptables kmod procps \
 && rm -rf /var/lib/apt/lists/*
RUN curl -fsSLo /tmp/cni.tgz "https://github.com/containernetworking/plugins/releases/download/v${CNI_VERSION}/cni-plugins-linux-${TARGETARCH}-v${CNI_VERSION}.tgz" \
 && curl -fsSL "https://github.com/containernetworking/plugins/releases/download/v${CNI_VERSION}/cni-plugins-linux-${TARGETARCH}-v${CNI_VERSION}.tgz.sha256" | awk '{print $1 "  /tmp/cni.tgz"}' | sha256sum -c - \
 && mkdir -p /opt/cni/bin && tar -xzf /tmp/cni.tgz -C /opt/cni/bin && rm /tmp/cni.tgz
COPY --from=docker /usr/local/bin/ /usr/local/bin/
COPY --from=nomad /bin/nomad /usr/local/bin/nomad
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

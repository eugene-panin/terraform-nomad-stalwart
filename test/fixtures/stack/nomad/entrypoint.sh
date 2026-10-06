#!/bin/sh
set -e
address=$(hostname -i | cut -d' ' -f1)
dnsmasq --listen-address="$address" --bind-interfaces --no-resolv --no-hosts --server=127.0.0.11
dockerd-entrypoint.sh dockerd --dns "$address" >/var/log/dockerd.log 2>&1 &
until docker info >/dev/null 2>&1; do sleep 1; done
exec nomad "$@"

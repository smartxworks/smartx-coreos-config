#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

if [ -e /run/ostree-live ]; then
    exit 0
fi

cat <<EOF > /etc/systemd/system-preset/45-scos.preset
disable getty@.service
enable ske-welcome.service
enable docker.service
enable kubelet.service
EOF

unlink /etc/systemd/system/getty.target.wants/getty@tty1.service

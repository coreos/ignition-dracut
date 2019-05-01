#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

set -euo pipefail

# Clean up the interfaces set up in the initramfs
# This mimics the behaviour of dracut's ifdown() in net-lib.sh
if ! [ -z "$(ls /sys/class/net)" ]; then
    for f in /sys/class/net/*; do
        interface=$(basename "$f")
        ip link set $interface down
        ip addr flush dev $interface
        rm -f -- /tmp/net.$interface.did-setup
    done
fi

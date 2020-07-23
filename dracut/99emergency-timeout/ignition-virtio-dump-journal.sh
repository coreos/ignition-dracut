#!/bin/bash
set -euo pipefail

port=/dev/virtio-ports/com.coreos.ignition.journal
if [ -e "${port}" ]; then
    # wait for the journal to wind down
    for i in {1..15}; do
        if journalctl -q -u systemd-journald.service --grep 'Journal stopped'; then
            break
        fi
        sleep 2
    done
    journalctl -o json > "${port}"
    # And this signals end of stream
    echo '{}' > "${port}"
else
    echo "Didn't find virtio port ${port}"
fi

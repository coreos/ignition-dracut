#!/bin/bash
set -euo pipefail

# Reads default kernel arguments
kargs=$(cat /sysroot/etc/ostree/kargs.d/karg_file)

# Copied from ignition-generator
cmdline_bool() {
    local value=$(cmdline_arg "$@")
    case "$value" in
        ""|0|no|off) return 1;;
        *) return 0;;
    esac
}

# Checks if kernel argument directory exists,
# then redeploy and reboot the system if it exists
reboot_if_kargs_dir_exists() {
    if [ -d /sysroot/etc/ostree/kargs.d ]; then
        ostree admin instutil set-kargs -v --sysroot=/sysroot --merge ${kargs}
        exec systemctl reboot
    fi
}

if $(cmdline_bool 'ignition.firstboot' 0); then
    reboot_if_kargs_dir_exists
fi

#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

set -e

cmdline=( $(</proc/cmdline) )

cmdline_arg() {
    local name="$1" value="$2"
    for arg in "${cmdline[@]}"; do
        if [[ "${arg%%=*}" == "${name}" ]]; then
            value="${arg#*=}"
        fi
    done
    echo "${value}"
}

cmdline_bool() {
    local value=$(cmdline_arg "$@")
    case "$value" in
        ""|0|no|off) return 1;;
        *) return 0;;
    esac
}

# We don't persist anything in the default networking case of ip=dhcp;
# NetworkManager does dhcp by default on connected interfaces by default anyways,
# and more importantly doing so can clash if a user provides static IP configuration
# via Ignition, as was supported in OpenShift 4.1.  See
# https://bugzilla.redhat.com/show_bug.cgi?id=1736875
ip=$(cmdline_arg ip)
if [ "${ip}" = "dhcp" ]; then
    exit 0
fi

# Unless overridden, propagate the kernel commandline networking into
# ifcfg files, so that users don't have to write the config in both kernel
# commandline *and* Ignition.
if ! $(cmdline_bool 'coreos.no_persist_ip' 0); then
    cp /tmp/ifcfg/* /sysroot/etc/sysconfig/network-scripts/
fi

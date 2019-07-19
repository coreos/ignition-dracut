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

if ! $(cmdline_bool 'coreos.no_persist_ip' 0); then
    cp /tmp/ifcfg/* /sysroot/etc/sysconfig/network-scripts/
fi


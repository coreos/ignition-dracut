#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

type info >/dev/null 2>&1 || . /lib/net-lib.sh

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

persist_ifcfg() {
    # We don't persist anything in the default networking case of ip=dhcp;
    # NetworkManager does dhcp by default on connected interfaces by default anyways,
    # and more importantly doing so can clash if a user provides static IP configuration
    # via Ignition, as was supported in OpenShift 4.1.  See
    # https://bugzilla.redhat.com/show_bug.cgi?id=1736875
    ip=$(cmdline_arg ip)
    if [ "${ip}" = "dhcp" ] || [ "${ip}" = "dhcp,dhcp6" ]; then
        return 0
    fi

    # Persist the hostname if the admin has elected to use the dracut method of
    # defining the IP on the commandline, but only if Ignition hasn't set the hostname.
    hpath="/sysroot/etc/hostname"
    hname=$(< /proc/sys/kernel/hostname)
    if [ ! -f "${hpath}" ]; then
        for iface in $(ls /sys/class/net)
        do
            # Find the totems indicating that dracut set up the interface
            iface_totems="/run/initramfs/net.${iface}"
            [ -f "${iface_totems}.did-setup" ] || continue;
            [ -f "${iface_totems}.hostname" ] || continue;

            # The format of the file is _the command used to set the hostname_
            # echo hostname > /proc/sys/kernel/hostname.
            read _ iface_hostname _ < "${iface_totems}.hostname"

            # Ensure that the hostname used by the kernel is the same one
            # used by this interface. This guard is intended to protect against
            # mixed `ip=` or where one is set via dhcp.
            if [ "${iface_hostname}" == "${hname}" ]; then
                echo "${hname}" > "${hpath}"
                echo -ne '/etc/hostname/\0' >> /sysroot/etc/selinux/ignition.relabel
                info "persisting hostname set by kargs for ${iface}"
                break
            fi
        done
    fi

    # Unless overridden, propagate the kernel commandline networking into
    # ifcfg files, so that users don't have to write the config in both kernel
    # commandline *and* Ignition.
    if ! $(cmdline_bool 'coreos.no_persist_ip' 0); then
        cp -n /tmp/ifcfg/* /sysroot/etc/sysconfig/network-scripts/
        echo -ne '/etc/sysconfig/network-scripts/\0' >> /sysroot/etc/selinux/ignition.relabel
    fi
}

# Encapsulate everything in a persist_ifcfg() function,
# Note that we cannot explicitly exit 0 since dracut directly sources the hook file,
# so exit 0 (or set -e) will cause the dracut init script to just exit.
persist_ifcfg "$@"


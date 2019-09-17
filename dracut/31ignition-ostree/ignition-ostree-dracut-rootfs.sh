#!/bin/bash
set -euo pipefail

rootmnt=/sysroot
tmproot=/run/ignition-ostree-rootfs

case "${1:-}" in
    detect)
        # This is obviously crude; perhaps in the future we could change ignition's `fetch`
        # stage to write out a file if the rootfs is being replaced or so.  But eh, it
        # works for now.
        has_rootfs=$(jq '.storage?.filesystems? // [] | map(select(.label == "root")) | length' < /run/ignition.json)
        if [ "${has_rootfs}" = "0" ]; then
            exit 0
        fi
        echo "Detected rootfs replacement in fetched Ignition config: /run/ignition.json"
        mkdir "${tmproot}"
        ;;
    save)
        # This one is in a private mount namespace since we're not "offically" mounting
        mount /dev/disk/by-label/root $rootmnt
        echo "Moving rootfs to RAM..."
        # OSTree added the immutable bit on the deployment root, and
        # cosa's create_disk added it to the rootfs
        chattr -i ${rootmnt} ${rootmnt}/ostree/deploy/*/deploy/*.0
        for x in boot ostree; do
            # TODO; copy instead of mv to avoid writes, since we're just
            # about to blow away the whole FS anyways?
            mv -Tn ${rootmnt}/${x} ${tmproot}/${x}
        done
        umount ${rootmnt}
        echo "Moved rootfs to RAM, pending redeployment: ${tmproot}"
        ;;
    restore)
        # This one is in a private mount namespace since we're not "offically" mounting
        mount /dev/disk/by-label/root $rootmnt
        echo "Restoring rootfs from RAM..."
        for x in boot ostree; do
            mv -Tn ${tmproot}/${x} ${rootmnt}/${x}
        done
        # And restore the immutable bits
        chattr +i ${rootmnt}/ostree/deploy/*/deploy/*.0 ${rootmnt}
        echo "...done"
        umount $rootmnt
        ;;
    *)
        echo "Unsupported operation: ${1:-}"
        ;;
esac

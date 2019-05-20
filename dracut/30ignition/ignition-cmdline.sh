#!/bin/bash
type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh
getargbool 0 ignition.firstboot || exit 0

ign_file="/sys/firmware/qemu_fw_cfg/by_name/opt/com.coreos/config/raw"
[ -e "$ign_file" ] || exit 0

opt_cmdline=$(jq -r '{dracut: .dracut.cmdline} | .[]' "$ign_file")
[ -n "$opt_cmdline" ] && echo "$opt_cmdline" > /etc/cmdline.d/ignition-cmdline.conf

exit 0

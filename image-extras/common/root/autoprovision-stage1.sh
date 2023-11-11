#!/bin/sh

# autoprovision stage 1: this script will be executed upon boot without a valid extroot (i.e. when rc.local is found and run from the internal overlay)

. /root/autoprovision-functions.sh

getPendriveSize()
{
    # this is needed for the mmc card in some (all?) Huawei 3G dongle.
    # details: https://dev.openwrt.org/ticket/10716#comment:4
    if [ -e /dev/sda ]; then
        # force re-read of the partition table
        head -c 1024 /dev/sda >/dev/null
    fi

    if (grep -q sda /proc/partitions) then
        cat /sys/block/sda/size
    else
        echo 0
    fi
}

hasBigEnoughPendrive()
{
    local size=$(getPendriveSize)
    if [ $size -ge 100000 ]; then
        log "Found a pendrive of size: $(($size / 2 / 1024)) MB"
        return 0
    else
        return 1
    fi
}

rereadPartitionTable()
{
    log "Rereading partition table"
    blockdev --rereadpt /dev/sda
}

setupPendrivePartitions()
{
    log "Erasing partition table"
    # erase partition table
    dd if=/dev/zero of=/dev/sda bs=1k count=256

    rereadPartitionTable

    log "Creating partitions"
    # sda1 is 'root'
    fdisk /dev/sda <<EOF

n
p
1


t
83
w
q
EOF
    log "Finished partitioning /dev/sda using fdisk"

    rereadPartitionTable

    until [ -e /dev/sda1 ]
    do
        echo "Waiting for partitions to show up in /dev"
        sleep 1
    done

    mkfs.ext4 -F -L root -U $rootUUID /dev/sda1

    log "Finished setting up filesystems"
}

setupExtroot()
{
    DEVICE="/dev/sda1"

    eval $(block info ${DEVICE} | grep -o -e 'UUID="\S*"')
    eval $(block info | grep -o -e 'MOUNT="\S*/overlay"')
    uci -q delete fstab.extroot
    uci set fstab.extroot="mount"
    uci set fstab.extroot.uuid="${UUID}"
    uci set fstab.extroot.target="${MOUNT}"
    uci commit fstab
    # at this point we could copy the entire root (a previous version of this script did that), or just the overlay from the flash,
    # but it seems to work fine if we just create an empty overlay that is only replacing the rc.local from the firmware.

    # let's write a new rc.local on the extroot that will shadow the one which is in the rom (to run stage2 instead of stage1)
    mount -U $rootUUID /mnt
    tar -C ${MOUNT} -cvf - . | tar -C /mnt -xf -
    cat >/mnt/upper/etc/rc.local <<EOF

# performance governor
echo performance > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor

/root/autoprovision-stage2.sh
EOF

    # TODO FIXME when this below is enabled then Chaos Calmer doesn't turn on the network and the device remains unreachable

    # make sure that we shadow the /var -> /tmp symlink in the new extroot, so that /var becomes persistent across reboots.
   # mkdir -p ${overlay_root}/var
    # KLUDGE: /var/state is assumed to be transient, so link it to tmp, see https://dev.openwrt.org/ticket/12228
   # cd ${overlay_root}/var
   # ln -s /tmp state
   # cd -

    log "Finished setting up extroot"
}

autoprovisionStage1()
{
    signalAutoprovisionWorking

    signalAutoprovisionWaitingForUser
    signalWaitingForPendrive

    until hasBigEnoughPendrive
    do
        echo "Waiting for a pendrive to be inserted"
        sleep 3
    done

    signalAutoprovisionWorking # to make it flash in sync with the USB led
    signalFormatting

    sleep 1

    setupPendrivePartitions
    sleep 1
    setupExtroot

    sync
    stopSignallingAnything
    reboot
}
#!/usr/bin/env bash

set -xe

. ./variables.sh

"$BASEDIR/init.sh"

# Must be run as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

export INMEM=0

if [ "$1" = "bootstrap" ]; then
    export MODE="bootstrap"
elif [ "$1" = "irmin" ]; then
    export MODE="irmin"
elif [ "$1" = "tezedge-inmem" ]; then
    export MODE="tezedge"
    export INMEM=1
else
    export MODE="tezedge"
fi

## Clean data from previous runs
umount /mnt/crash-test/bootstrap_db || true
umount /mnt/crash-test/context || true
umount /mnt/crash-test || true
dmsetup remove log || true
rm -rf /tmp/valid_context /tmp/invalid_context "$MOUNT_PATH"
mkdir -p "$CONTEXT_PATH"

# if [ $INMEM = 1 ]; then
#     export CONTEXT_PATH=$MOUNT_PATH
# fi

## Format `/dev/sdb` and `/dev/sdc`
mkfs.btrfs -f $DEV_LOG
mkfs.btrfs -f $DEV_REPLAY

## Create the device mapper
TABLE="0 $(blockdev --getsz $DEV_LOG) log-writes $DEV_LOG $DEV_REPLAY"
dmsetup create log --table "$TABLE"
mkfs.btrfs -f /dev/mapper/log

## Add a mark, to not replay requests prior to the formatting
dmsetup message log 0 mark mkfs
mount /dev/mapper/log "$MOUNT_PATH"

mkdir -p "$MOUNT_PATH/bootstrap_db"
mount -t tmpfs -o size=2000M tmpfs "$MOUNT_PATH/bootstrap_db"

## Apply tezos blocks
dmsetup message log 0 mark start
"$BASEDIR/apply_block.sh"
dmsetup message log 0 mark fsync-end

umount "$MOUNT_PATH/bootstrap_db"
umount "$MOUNT_PATH"
dmsetup remove log

## Replay requests until `mkfs` mark
"$LOG_WRITES_PATH/replay-log" --log $DEV_REPLAY --replay $DEV_LOG --end-mark mkfs

## Replay requests until `fsync-end` mark
## After every `FUA` request, we run the integrity check on the database
#"$LOG_WRITES_PATH/replay-log" -v --log $DEV_REPLAY --replay $DEV_LOG --start-mark mkfs --fsck "$BASEDIR/verify_context.sh" --check fua
"$LOG_WRITES_PATH/replay-log" -v --log $DEV_REPLAY --replay $DEV_LOG --start-mark mkfs --end-mark fsync-end --fsck "$BASEDIR/verify_context.sh" --check fua

rm -rf "$MOUNT_PATH"

set +x
touch /tmp/valid_context /tmp/invalid_context

echo -e "\nResult:"
echo "- $(cat /tmp/invalid_context | wc -c) invalid context"
echo "- $(cat /tmp/valid_context | wc -c) valid context"

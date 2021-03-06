#!/usr/bin/env bash

set -xe

## Kill all child process on exit
trap 'pkill -e -P $$' EXIT

. ./variables.sh

. "$BASEDIR/init.sh"

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

if [ "$MODE" = "bootstrap" ]; then
    . "$BASEDIR/start_first_node.sh"
fi

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

if [ "$MODE" != "bootstrap" ]; then
    mkdir -p "$MOUNT_PATH/bootstrap_db"
    mount -t tmpfs -o size=2000M tmpfs "$MOUNT_PATH/bootstrap_db"
fi

## Apply tezos blocks
dmsetup message log 0 mark start
. "$BASEDIR/apply_block.sh"
dmsetup message log 0 mark fsync-end

if [ "$MODE" != "bootstrap" ]; then
    umount "$MOUNT_PATH/bootstrap_db"
fi
umount "$MOUNT_PATH"
dmsetup remove log

## Replay requests until `mkfs` mark
"$LOG_WRITES_BIN" --log $DEV_REPLAY --replay $DEV_LOG --end-mark mkfs

## Replay requests until `fsync-end` mark
## After every `FUA` request, we run the integrity check on the database
"$LOG_WRITES_BIN" -v --log $DEV_REPLAY --replay $DEV_LOG --start-mark mkfs --end-mark fsync-end --fsck "$BASEDIR/verify_context.sh" --check fua

rm -rf "$MOUNT_PATH"

set +x
if [ "$MODE" != "bootstrap" ]; then
    touch /tmp/valid_context /tmp/invalid_context

    echo -e "\nResult:"
    echo "- $(cat /tmp/invalid_context | wc -c) invalid context"
    echo "- $(cat /tmp/valid_context | wc -c) valid context"
fi

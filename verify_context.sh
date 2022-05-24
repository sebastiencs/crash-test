#!/usr/bin/env bash

## Run integrity check, to make sure that the context is valid

set -xe

mount -o ro /dev/sdb "$MOUNT_PATH" || exit 0

if [ "$MODE" = "tezedge" ]; then
    FILE="sizes.db"
elif [ "$MODE" = "irmin" ]; then
    FILE="store.pack"
fi

ls -laR "$MOUNT_PATH" || true

if [ ! -f "$CONTEXT_PATH/$FILE" ];then
    echo "Context does not exist"
    sleep 0.1s
    umount "$MOUNT_PATH"
    exit 0
fi

ls -laR "$CONTEXT_PATH/"

rm -rf /tmp/context
cp -r "$CONTEXT_PATH" /tmp/context

cd /home/sebastien/github/tezedge
# cd "$TEZEDGE_PATH" #TODO: Use this

set +e

RESULT=1
if [ "$MODE" = "tezedge" ]; then
    "$TEZEDGE_PATH/target/release/context-tool" is-valid-context --context-path "$CONTEXT_PATH"
    RESULT=$?
elif [ "$MODE" = "irmin" ]; then
    cargo test --release -p tezos_interop --test integrity_check -- --nocapture
    RESULT=$?
fi

set -e

if [ $RESULT -gt 0 ]; then
    echo -n 1 >> /tmp/invalid_context
else
    echo -n 1 >> /tmp/valid_context
fi

umount "$MOUNT_PATH" || true

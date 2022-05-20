#!/usr/bin/env bash

## Run integrity check, to make sure that the context is valid

set -xe

mount -o ro /dev/sdb "$CONTEXT_PATH" || exit 0

#FILE="store.pack"
FILE="sizes.db"

ls -laR "$CONTEXT_PATH" || true

if [ ! -f "$CONTEXT_PATH/$FILE" ];then
    echo "Context does not exist"
    sleep 0.1s
    umount "$CONTEXT_PATH"
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

umount "$CONTEXT_PATH" || true

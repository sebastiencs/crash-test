#!/usr/bin/env bash

set -xe

TARGET_DIR=$MOUNT_PATH
#TARGET_DIR=/home/sebastien/tmp/replay

# BLOCK=BLB6MA3z5jZmngy6CSbDFJ5kXhDfz1B9Zb3EPLxSm9oipvHkaxU # 10
# BLOCK=BLjhhb3SvKgLL8dk7223oE69RmKbJo97UTtWyorT76U2MAgkWdn # 100
#BLOCK=BLJXpn34ZfhtjFGb4gh61k8FLCzqNx2ZU7brBhihtYHtqghYe6U # 400
#BLOCK=BKz1GxoMayAmSKeVJSRBwWSzQcYdmoxgFUzBstBoZu3yiNdQE7f #1_000
#BLOCK=BMYopWiktTXmocoxeCZYvtLWbeqyzuhLovj5RREuEEyzk4z6H8L # 10_000
#BLOCK=BKop5gi9HpsUsBDDL78wVGJg2WcRUtUU384jcov2GP2Xdiu2WnZ # 5_000

if [ "$MODE" = "tezedge" ]; then
    STORAGE="tezedge"
elif [ "$MODE" = "irmin" ]; then
    STORAGE="irmin"
fi

if [ "$INMEM" = 1 ]; then
    BLOCK=BLJXpn34ZfhtjFGb4gh61k8FLCzqNx2ZU7brBhihtYHtqghYe6U # 400
    TEZEDGE_CONTEXT=inmem
else
    BLOCK=BLB6MA3z5jZmngy6CSbDFJ5kXhDfz1B9Zb3EPLxSm9oipvHkaxU # 10
    TEZEDGE_CONTEXT=ondisk
fi

export TEZEDGE_GC_DELAY_SNAPSHOT_SEC="0"

"$TEZEDGE_PATH/target/release/light-node" \
    --config-file "$TEZEDGE_PATH/light_node/etc/tezedge/tezedge.config" \
    --network=hangzhounet \
    --log-level info \
    --protocol-runner "$TEZEDGE_PATH/target/release/protocol-runner" \
    --tezos-data-dir ~/tmp/hangzhou/ \
    replay \
    --target-path "$TARGET_DIR" \
    --to-block "$BLOCK" \
    --tezos-context-storage="$STORAGE" \
    --context-kv-store="$TEZEDGE_CONTEXT"

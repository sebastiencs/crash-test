#!/usr/bin/env bash

set -xe

TARGET_DIR=$MOUNT_PATH

if [ "$MODE" = "tezedge" ] || [ "$MODE" = "irmin" ]; then

    if [ "$MODE" = "tezedge" ]; then
        STORAGE="tezedge"
    elif [ "$MODE" = "irmin" ]; then
        STORAGE="irmin"
    fi

    if [ "$INMEM" = 1 ]; then
        BLOCK=$BLOCK_LEVEL_400 # Need to process a lot more blocks, to let time for snapshot creation
        TEZEDGE_CONTEXT=inmem
    else
        BLOCK=$BLOCK_LEVEL_10
        TEZEDGE_CONTEXT=ondisk
    fi

    export TEZEDGE_GC_DELAY_SNAPSHOT_SEC="0"

    "$TEZEDGE_PATH/target/release/light-node" \
        --config-file "$TEZEDGE_PATH/light_node/etc/tezedge/tezedge.config" \
        --network="$NETWORK" \
        --log-level info \
        --protocol-runner "$TEZEDGE_PATH/target/release/protocol-runner" \
        --tezos-data-dir "$BASEDIR/database" \
        replay \
        --target-path "$TARGET_DIR" \
        --to-block "$BLOCK" \
        --tezos-context-storage="$STORAGE" \
        --context-kv-store="$TEZEDGE_CONTEXT"

else
    ## Bootstrap test

    "$TEZEDGE_PATH/target/release/light-node" \
        --protocol-runner "$TEZEDGE_PATH/target/release/protocol-runner" \
        --tezos-data-dir "$TARGET_DIR" \
        --network="$NETWORK" \
        --bootstrap-db-path=bootstrap_db \
        --tezos-context-storage=tezedge \
        --p2p-port 19732 \
        --peers="127.0.0.1:9733" \
        --rpc-port=18733 \
        --config-file "$TEZEDGE_PATH/light_node/etc/tezedge/tezedge.config" &

    TPID=$!

    block=0
    previous_block=100000
    attempts=0
    while [ $attempts -lt 60 ]; do
        sleep 1
        b=$(curl -s localhost:18733/chains/main/blocks/head | jq .header.level)
        block=${b:-$block}
        echo "===> Block level $block"
        if [ $block -gt 10 ]; then
            break
        fi
        attempts=$(($attempts + 1))
    done

    kill $TPID
    sleep 5s
fi

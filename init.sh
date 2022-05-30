#!/usr/bin/env bash

# Compiles tezedge and log-writes when the binaries are not found

set -xe

if [ ! -f "$TEZEDGE_PATH/target/release/light-node" ];then
    cd "$TEZEDGE_PATH"
    cargo build --release
fi

if [ ! -f "$LOG_WRITES_PATH/replay-log" ];then
    cd "$LOG_WRITES_PATH"
    make
fi

if [ ! -d "$BASEDIR/database/bootstrap_db" ];then
    # Download at least 1000 headers on ithacanet

    mkdir -p "$BASEDIR/database"

    "$TEZEDGE_PATH/target/release/light-node" \
        --config-file "$TEZEDGE_PATH/light_node/etc/tezedge/tezedge.config" \
        --network=ithacanet \
        --log-level info \
        --protocol-runner "$TEZEDGE_PATH/target/release/protocol-runner" \
        --tezos-data-dir "$BASEDIR/database" \
        --tezos-context-storage=tezedge \
        --context-kv-store=ondisk \
        --p2p-port 9733 \
        --rpc-port=18734 &

    TPID=$!

    block=0
    previous_block=100000
    attempts=0
    while [ $attempts -lt 2160 ]; do
        sleep 5
        b=$(curl -s localhost:18733/chains/main/blocks/head | jq .header.level)
        block=${b:-$block}
        echo "===> Block level $block"
        if [ $block -gt 1000 ]; then
            break
        fi
        attempts=$(($attempts + 1))
    done

    kill $TPID
    sleep 5s
fi

rm -rf "$BASEDIR/database/context"

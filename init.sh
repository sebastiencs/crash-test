#!/usr/bin/env bash

# Compiles tezedge and log-writes when the binaries are not found

set -xe

if [ ! -d "$TEZEDGE_PATH" ];then
    cd "$BASEDIR"
    git clone -b develop --depth 1 git@github.com:tezedge/tezedge.git tezedge
fi

if [ ! -f "$TEZEDGE_PATH/target/release/light-node" ];then
    cd "$TEZEDGE_PATH"
    cargo build --release
fi

if [ ! -d "$LOG_WRITES_PATH" ];then
    cd "$BASEDIR"
    git clone https://github.com/sebastiencs/log-writes-rs.git log-writes-rs
fi

if [ ! -f "$LOG_WRITES_BIN" ];then
    cd "$LOG_WRITES_PATH"
    cargo build --release
fi

if [ ! -d "$BASEDIR/database/bootstrap_db" ];then
    # Download headers/operations on ithacanet

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
    while [ $attempts -lt 5000 ]; do
        sleep 5
        b=$(curl -s localhost:18734/chains/main/blocks/head | jq .header.level)
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

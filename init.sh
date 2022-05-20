#!/usr/bin/env bash

# Compiles tezedge and log-writes when the binaries are not found

set -xe

if [ ! -f "$TEZEDGE_PATH/target/release/light-node" ];then
    cd "$TEZEDGE_PATH"
    cargo build --release
fi

if [ ! -f "$LOG_WRITES_PATH/replay_log" ];then
    cd "$LOG_WRITES_PATH"
    make
fi

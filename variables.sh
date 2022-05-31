#!/usr/bin/env bash

export BASEDIR=$(cd "$(dirname "$0")" && pwd)

export DEV_LOG=/dev/sdb
export DEV_REPLAY=/dev/sdc

export TEZEDGE_PATH="$BASEDIR/tezedge"

export LOG_WRITES_PATH="$BASEDIR/log-writes-rs"
export LOG_WRITES_BIN="$LOG_WRITES_PATH/target/release/log-write"

export MOUNT_PATH=/mnt/crash-test
export CONTEXT_PATH="$MOUNT_PATH/context"

export LD_LIBRARY_PATH="$TEZEDGE_PATH/tezos/sys/lib_tezos/artifacts/"
export RUST_BACKTRACE=1

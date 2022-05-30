#!/usr/bin/env bash

set -xe

SLEEP="10s"
if [ ! -d /tmp/first_node ]; then
    SLEEP="40s"
fi

mkdir -p /tmp/first_node
cd /tmp/first_node

"$TEZEDGE_PATH/target/release/light-node" \
    --config-file "$TEZEDGE_PATH/light_node/etc/tezedge/tezedge.config" \
    --network=hangzhounet \
    --log-level info \
    --protocol-runner "$TEZEDGE_PATH/target/release/protocol-runner" \
    --tezos-data-dir "$BASEDIR/database" \
    --tezos-context-storage=tezedge \
    --context-kv-store=inmem \
    --disable-bootstrap-lookup \
    --p2p-port 9733 \
    --rpc-port=18734 &

sleep "$SLEEP"

cd "$BASEDIR"

#!/usr/bin/env bash

set -xe

TARGET_DIR=$MOUNT_PATH

# BLOCK=BLB6MA3z5jZmngy6CSbDFJ5kXhDfz1B9Zb3EPLxSm9oipvHkaxU # 10
# BLOCK=BLjhhb3SvKgLL8dk7223oE69RmKbJo97UTtWyorT76U2MAgkWdn # 100
#BLOCK=BLJXpn34ZfhtjFGb4gh61k8FLCzqNx2ZU7brBhihtYHtqghYe6U # 400
#BLOCK=BKz1GxoMayAmSKeVJSRBwWSzQcYdmoxgFUzBstBoZu3yiNdQE7f #1_000
#BLOCK=BMYopWiktTXmocoxeCZYvtLWbeqyzuhLovj5RREuEEyzk4z6H8L # 10_000
#BLOCK=BKop5gi9HpsUsBDDL78wVGJg2WcRUtUU384jcov2GP2Xdiu2WnZ # 5_000

if [ "$MODE" = "tezedge" ] || [ "$MODE" = "irmin" ]; then

    if [ "$MODE" = "tezedge" ]; then
        STORAGE="tezedge"
    elif [ "$MODE" = "irmin" ]; then
        STORAGE="irmin"
    fi

    if [ "$INMEM" = 1 ]; then
        BLOCK=BMK3jvChnpvqHqHvPErHk7WGWyAVmvjwq8EMj8QJ5t3TRCy3Gqd # 400 ithaca
        # BLOCK=BLJXpn34ZfhtjFGb4gh61k8FLCzqNx2ZU7brBhihtYHtqghYe6U # 400
        TEZEDGE_CONTEXT=inmem
    else
        BLOCK=BLqNTDzsU6hETYiAu4s1Ring6MsC5StmNps3fzcnxbRVW6LGk9Y # 10 ithaca
        # BLOCK=BLB6MA3z5jZmngy6CSbDFJ5kXhDfz1B9Zb3EPLxSm9oipvHkaxU # 10
        TEZEDGE_CONTEXT=ondisk
    fi

    export TEZEDGE_GC_DELAY_SNAPSHOT_SEC="0"

    "$TEZEDGE_PATH/target/release/light-node" \
        --config-file "$TEZEDGE_PATH/light_node/etc/tezedge/tezedge.config" \
        --network=ithacanet \
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
        --network=ithacanet \
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

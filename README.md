# Testing Tezedge crash consistency

Tests to ensure that tezedge is able to resume after a crash occurs, and the integrity of the database is not altered.  

We are simulating crashes by saving the storage after every block IO request, at the block layer.  
We then attempt to restart the node on top of the saved storage, and perform some integrity checks.  
The tests are using [dm-log-writes](https://www.kernel.org/doc/html/latest/admin-guide/device-mapper/log-writes.html).  

![image](https://www.thomas-krenn.com/de/wikiDE/images/e/e0/Linux-storage-stack-diagram_v4.10.png)

When an application write to the storage (with the syscalls `write(2)`, `chmod(2)`, `fsync(2)`, etc), it translates
at the block layer to a sequence of requests: [`REQ_META`, `REQ_PREFLUSH`, `REQ_FUA`, ..](https://github.com/torvalds/linux/blob/8ab2afa23bd197df47819a87f0265c0ac95c5b6a/include/linux/blk_types.h#L387-L422)

We ensure that after every FUA requests, the database is in a valid state, and that Tezedge is able to restart with
that database.   
We focus only on the request `FUA` (Force Unit Access), because attempting to read the storage after other requests leads to invalid file system.  
A `FUA` request can be triggered from an application by calling `fsync` or `fdatasync`

This was tested in a VM with Ubuntu 22.04 and 2 additional partitions:
- `/dev/sdb` 2 GB
- `/dev/sdc` 2 GB

Note: The first run of any of those tests will take a few hours to complete, because it needs to download all block headers on testnet.  
Downloading the headers is required only once.

## Tezedge context storage (persistent)

This test applies 10 blocks from ithacanet

##### Run:
```
$ sudo ./run_test.sh tezedge
```
##### Result:
```
Result:
- 0 invalid context
- 81 valid context
```
After every `FUA` request, a valid context was found

## Irmin context storage 

This test applies 10 blocks from ithacanet

##### Run:
```
$ sudo ./run_test.sh irmin
```
##### Result:
```
Result:
- 0 invalid context
- 0 valid context
```
The test did not find any valid or invalid context.  
This is because `irmin` doesn't call `fsync/fdatasync`

## Tezedge context storage (in memory)

This tests the in-memory context.  
While everything is in RAM, it periodically makes a snapshot on disk.  
This test ensure that the snapshots are valid.

##### Run:
```
$ sudo ./run_test.sh tezedge-inmem
```
##### Result:
```
Result:
- 0 invalid context
- 14 valid context
```

## Full bootstrapping test (block + context storages)

##### Run:
```
$ sudo ./run_test.sh bootstrap
```

This will bootstrap the node on ithacanet.  
After every `FUA` request, it will attempt to continue the bootstrapping process.  

##### Result:

The tezedge node is always able to continue the bootstrapping and apply the next blocks

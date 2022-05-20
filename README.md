# Testing Tezedge crash consistency

Tests to ensure that tezedge is able to resume after a crash occurs, and the integrity of the database is not altered

This was tested in a VM with Ubuntu 22.04 and 2 additional partitions:
- `/dev/sdb` 2 GB
- `/dev/sdc` 2 GB

The tests are using [dm-log-writes](https://www.kernel.org/doc/html/latest/admin-guide/device-mapper/log-writes.html).  
They replay every block requests made to the storage, and after every [FUA](https://github.com/torvalds/linux/blob/master/Documentation/block/writeback_cache_control.rst)
request they check the integrity of the database.  
A `FUA` request is triggered when the userspace program calls `fsync` or `fdatasync`

## Tezedge context storage (persistent)

This test applies 10 blocks from hanghzounet

##### Run:
```
$ sudo ./replay tezedge
```
##### Result:
```
Result:
- 0 invalid context
- 81 valid context
```
After every `FUA` request, a valid context was found

## Irmin context storage 

This test applies 10 blocks from hanghzounet

##### Run:
```
$ sudo ./replay irmin
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
$ sudo ./replay tezedge-inmem
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
$ sudo ./replay bootstrap
```

This will bootstrap the node on hangzhounet.  
After every `FUA` request, it will attempt to continue the bootstrapping process.  
The test takes several hours to complete.

##### Result:

The tezedge node is always able to continue the bootstrapping and apply the next blocks

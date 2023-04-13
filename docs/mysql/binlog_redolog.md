### binlog写入机制
- 事务执行过程中，先写到`binlog cache` ，事务提交后，binlog cache 中的内容持久化到磁盘
- 一个事务的binlog，是不能被拆开的，无论事务多大也要确保一次性写入
- `binlog cache`每个线程都持有一片内存
- 事务提交后，线程把binlog cache 写入磁盘，然后清空cache
- write 是将binlog cache的内容放入到文件系统的page cache
- fsync 会将page cache 数据持久化道磁盘

![](http://image.heysq.com/wiki/mysql/binlog.png)

### sync_binlog
- sync-binlog为0，每次事务提交都会write到page cache，不会fsync
- sync-binlog为1，每次提交事务都会执行fsync
- sync-binlog>1 时，表示每次提交事务都会write，累计N个事务时才会fsync
- sync-binlog为1，性能影响较大
- sync-binlog为N时，重启会丢失最近N个事务的binlog日志

### redolog写入机制
- redo log buffer，事务执行过程中，会先写buffer
- 事务执行过程中，部分redo log buffer 会被写入到磁盘
- innodb 后台线程，定时将redo log buffer 中的日志刷到磁盘

### redolog buffer 不需要每次新增都持久化到磁盘
- 事务执行中还没提交，重启后丢失了一部分就回滚事务

### redo log 状态
- 在redo log buffer中
- 在文件系统page cache
- 在磁盘中

### redo log 写入策略 innodb_flush_log_at_trx_commit配置参数
- 0：每次事务提交都留在redo log buffer
- 1：每次事务提交都将redo log持久到磁盘
- 2：每次事务提交都写到page cache

### 事务的部分redo log写入到磁盘
- redo log buffer 占用 innodb_log_buffer_size一半，后台线程主动写到page cache
- 并行的其他事务提交，将这个事务的redo log buffer中的内容带上，且redo log 配置参数设置为1时，刷到磁盘

### 双一配置
- sync-binlog 设置为1
- innodb_flush_log_at_trx_commit 设置为1
- 一个事务提交前，两阶段提交，redo log刷盘一次，binlog刷盘一次
- redo log 状态改为commit的时候不会进行fsync，因为只要binlog 写磁盘成功，就算redo log 的状态还是prepare也没有关系会被认为事务已经执行成功，所以只需要write 到page cache就ok了，没必要再浪费io主动去进行一次fsync

### 组提交
- 每次redo log 落盘时，携带多个提交事务的redo log buffer
- binlog也可以组提交
![](http://image.heysq.com/wiki/mysql/group_commit.png)

### binlog组提交
- binlog_group_commit_sync_delay 参数，表示延迟多少微秒后才调用 fsync
- binlog_group_commit_sync_no_delay_count 参数，表示累积多少次以后才调用 fsync




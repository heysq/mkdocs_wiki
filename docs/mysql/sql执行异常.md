### 查询长时间不返回
- 表被锁住，等MDL锁 `lock table t write`
- 表等待Flush，如果flush阻塞的时候，select也会阻塞
	- `flush tables t with read lock`
	- `flush tables with read lock`
- 等待行锁，当前查询记录有行锁时，如果查询要加读锁就会阻塞当前查询
	- `select * from t where id = 1 lock in share mode;`

### 查询慢
- 查询条件字段没有命中索引，造成全表扫描
- 查询的行正在其他事务被不断更新，然后快照读需要不断的用undo log 去还原可见的MVCC版本
	- lock in share mode 返回特别快，因为是当前读
![](/images/mysql/sql执行异常.png)
- sql语句本身问题，可以通过查询重写来修改
- mysql本身选错了索引，`force index` 修正，或者删除选错的索引

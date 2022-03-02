### 为什么InnoDB引擎 count(*) 这么慢？
- 每条记录在数据库中都有多个版本，多个事务进行count计数的结果可能是不一样的
- 需要去除所有记录一行一行检查计数
- count时遍历最小的树

### show table status
- 结果中的table_rows不准确，采样估算表中有多少行记录
- 误差40-50%

### 加速count速度和准确度
- 设置redis缓存，速度可以，但是数据总有误差，且易丢失
- 这两个不同的存储构成的系统，不支持分布式事务，无法拿到精确一致的视图
- 用mysql的表存，开启事务进行操作

### 不同的count
- count是一个聚合函数，对一个结果集返回的数据一一进行判断，如果count的参数不是NULL，就进行累加1，然后返回累计值
- count(*), count(id), count(1) 都表示返回结果集中记录的总数
- count(字段)表示结果集中，字段部位null的总数
- count(*) 每一行肯定不是null，按行累加
- count(id) 遍历表，取出每行的id，server层判断不是null，就累加1
- count(1) 遍历表，不取值，server层对1进行累计
- count(字段)
	- 字段定义不允许为null，这判断不是null，累加1
	- 字段定义允许为null，判断到有可能是 null，还要把值取出来再判断一下，不是 null 才累加
- 按照效率排序count(字段) < count(id) < count(1) ≈ count(*)

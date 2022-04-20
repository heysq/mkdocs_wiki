> 笔记来自微信公众号 

> 常用限流算法的应用场景和实现原理

> 原创 KevinYan11 网管叨bi叨 2020-12-20 10:28

> [常用限流算法的应用场景和实现原理](https://mp.weixin.qq.com/s?__biz=MzUzNTY5MzU2MA==&mid=2247486937&idx=1&sn=d4ea6ebb38c52e8004e73f235bde9848&scene=21#wechat_redirect)

### 场景
- 在高并发业务场景下，保护系统时，常用的"三板斧"有："熔断、降级和限流"。
- 业务代码中的逻辑限流

### 常见限流算法
- 计数器
- 滑动敞口
- 漏桶
- 令牌桶

### 计数器
- 计数器是一种比较简单粗暴的限流算法，思想是在固定时间窗口内对请求进行计数，与阀值进行比较判断是否需要限流
- 一旦到了时间临界点，将计数器清零

#### 缺陷
- 可以在清零的前一秒和后一秒，两秒内发送阈值乘2的请求
- 一旦请求数量瞬间变多，还是会有崩溃的风险

![](/images/go/count.png)

#### 简单代码实现
```go
type LimitRate struct {
   rate  int           //阀值
   begin time.Time     //计数开始时间
   cycle time.Duration //计数周期
   count int           //收到的请求数
   lock  sync.Mutex    //锁
}

func (limit *LimitRate) Allow() bool {
   limit.lock.Lock()
   defer limit.lock.Unlock()

   // 判断收到请求数是否达到阀值
   if limit.count == limit.rate-1 {
      now := time.Now()
      // 达到阀值后，判断是否是请求周期内
      if now.Sub(limit.begin) >= limit.cycle {
         limit.Reset(now)
         return true
      }
      return false
   } else {
      limit.count++
      return true
   }
}

func (limit *LimitRate) Set(rate int, cycle time.Duration) {
   limit.rate = rate
   limit.begin = time.Now()
   limit.cycle = cycle
   limit.count = 0
}

func (limit *LimitRate) Reset(begin time.Time) {
   limit.begin = begin
   limit.count = 0
}
```

### 滑动窗口
- 滑动窗口算法将一个大的时间窗口分成多个小窗口，每次大窗口向后滑动一个小窗口，并保证大的窗口内流量不会超出最大值
- 比固定窗口的流量曲线更加平滑
- 滑动时间窗口，我们可以把1s的时间窗口划分成10个小窗口，或者想象窗口有10个时间插槽time slot, 每个time slot统计某个100ms的请求数量。每经过100ms，有一个新的time slot加入窗口，早于当前时间1s的time slot出窗口
- 窗口内最多维护10个time slot

#### 缺陷
- 滑动窗口算法是固定窗口的一种改进，但从根本上并没有真正解决固定窗口算法的临界突发流量问题

#### 代码实现
```go
package main

import (
	"fmt"
	"sync"
	"time"
)

type timeSlot struct {
	timestamp time.Time // 这个timeSlot的时间起点
	count     int       // 落在这个timeSlot内的请求数
}

// 统计整个时间窗口中已经发生的请求次数
func countReq(win []*timeSlot) int {
	var count int
	for _, ts := range win {
		count += ts.count
	}
	return count
}

type SlidingWindowLimiter struct {
	mu           sync.Mutex    // 互斥锁保护其他字段
	SlotDuration time.Duration // time slot的长度
	WinDuration  time.Duration // sliding window的长度
	numSlots     int           // window内最多有多少个slot
	windows      []*timeSlot
	maxReq       int // 大窗口时间内允许的最大请求数
}

func NewSliding(slotDuration time.Duration, winDuration time.Duration, maxReq int) *SlidingWindowLimiter {
	return &SlidingWindowLimiter{
		SlotDuration: slotDuration,
		WinDuration:  winDuration,
		numSlots:     int(winDuration / slotDuration),
		maxReq:       maxReq,
	}
}

func (l *SlidingWindowLimiter) validate() bool {
	l.mu.Lock()
	defer l.mu.Unlock()

	now := time.Now()
	// 已经过期的time slot移出时间窗
	timeoutOffset := -1
	for i, ts := range l.windows {
		if ts.timestamp.Add(l.WinDuration).After(now) {
			break
		}
		timeoutOffset = i
	}
	if timeoutOffset > -1 {
		l.windows = l.windows[timeoutOffset+1:]
	}

	// 判断请求是否超限
	var result bool
	if countReq(l.windows) < l.maxReq {
		result = true
	}

	// 记录这次的请求数
	var lastSlot *timeSlot
	if len(l.windows) > 0 {
		lastSlot = l.windows[len(l.windows)-1]
		if lastSlot.timestamp.Add(l.SlotDuration).Before(now) {
			// 如果当前时间已经超过这个时间插槽的跨度，那么新建一个时间插槽
			lastSlot = &timeSlot{timestamp: now, count: 1}
			l.windows = append(l.windows, lastSlot)
		} else {
			lastSlot.count++
		}
	} else {
		lastSlot = &timeSlot{timestamp: now, count: 1}
		l.windows = append(l.windows, lastSlot)
	}

	return result
}

func (l *SlidingWindowLimiter) LimitTest() string {
	if l.validate() {
		return "Accepted"
	} else {
		return "Ignored"
	}
}

func main() {
	limiter := NewSliding(100*time.Millisecond, time.Second, 10)
	for i := 0; i < 5; i++ {
		fmt.Println(limiter.LimitTest())
	}
	time.Sleep(100 * time.Millisecond)
	for i := 0; i < 5; i++ {
		fmt.Println(limiter.LimitTest())
	}
	fmt.Println(limiter.LimitTest())
	for _, v := range limiter.windows {
		fmt.Println(v.timestamp, v.count)
	}

	fmt.Println("moments later...")
	time.Sleep(time.Second)
	for i := 0; i < 7; i++ {
		fmt.Println(limiter.LimitTest())
	}
	for _, v := range limiter.windows {
		fmt.Println(v.timestamp, v.count)
	}
}

```

### 漏桶
#### 算法思想
- 漏桶算法是首先想象有一个木桶，桶的容量是固定的。当有请求到来时先放到木桶中，处理请求的worker以固定的速度从木桶中取出请求进行相应
- 如果木桶已经满了，直接返回请求频率超限的错误码或者页面

#### 使用场景
- 漏桶算法是流量最均匀的限流实现方式，一般用于流量“整形”
- 例如保护数据库的限流，先把对数据库的访问加入到木桶中，worker再以db能够承受的qps从木桶中取出请求，去访问数据库

#### 缺陷
- 木桶流入请求的速率是不固定的，但是流出的速率是恒定的。能保护系统资源不被打满
- 面对突发流量时会有大量请求失败，不适合电商抢购和微博出现热点事件等场景的限流

#### 简单代码实现
```go
// 一个固定大小的桶，请求按照固定的速率流出
// 请求数大于桶的容量，则抛弃多余请求

type LeakyBucket struct {
	rate       float64    // 每秒固定流出速率
	capacity   float64    // 桶的容量
	water      float64    // 当前桶中请求量
	lastLeakMs int64      // 桶上次漏水微秒数
	lock       sync.Mutex // 锁
}

func (leaky *LeakyBucket) Allow() bool {
	leaky.lock.Lock()
	defer leaky.lock.Unlock()

	now := time.Now().UnixNano() / 1e6
	// 计算剩余水量,两次执行时间中需要漏掉的水
	leakyWater := leaky.water - (float64(now-leaky.lastLeakMs) * leaky.rate / 1000)
	leaky.water = math.Max(0, leakyWater)
	leaky.lastLeakMs = now
	if leaky.water+1 <= leaky.capacity {
		leaky.water++
		return true
	} else {
		return false
	}
}

func (leaky *LeakyBucket) Set(rate, capacity float64) {
	leaky.rate = rate
	leaky.capacity = capacity
	leaky.water = 0
	leaky.lastLeakMs = time.Now().UnixNano() / 1e6
}
```

### 令牌桶
#### 算法思想
- 倒着的漏桶
- 以恒定的速率向桶中添加令牌
- 木桶满了则不再加入令牌。服务收到请求时尝试从木桶中取出一个令牌
- 令牌桶空闲时，可以攒着最高的限额数的令牌
- 由于木桶内只要有令牌，请求就可以被处理，所以令牌桶算法可以支持突发流量

![](/images/go/lingpaitong.png)

#### 参数设置
- 木桶的容量  - 考虑业务逻辑的资源消耗和机器能承载并发处理多少业务逻辑。
- 生成令牌的速度 - 太慢的话起不到“攒”令牌应对突发流量的效果

#### 简单代码实现
```go
type TokenBucket struct {
	rate         int64 //固定的token放入速率, r/s
	capacity     int64 //桶的容量
	tokens       int64 //桶中当前token数量
	lastTokenSec int64 //上次向桶中放令牌的时间的时间戳，单位为秒

	lock sync.Mutex
}

func (bucket *TokenBucket) Take() bool {
	bucket.lock.Lock()
	defer bucket.lock.Unlock()

	now := time.Now().Unix()
	bucket.tokens = bucket.tokens + (now-bucket.lastTokenSec)*bucket.rate // 先添加令牌
	if bucket.tokens > bucket.capacity {
		bucket.tokens = bucket.capacity
	}
	bucket.lastTokenSec = now
	if bucket.tokens > 0 {
		// 还有令牌，领取令牌
		bucket.tokens--
		return true
	} else {
		// 没有令牌,则拒绝
		return false
	}
}

func (bucket *TokenBucket) Init(rate, cap int64) {
	bucket.rate = rate
	bucket.capacity = cap
	bucket.tokens = 0
	bucket.lastTokenSec = time.Now().Unix()
}
```

### 官方限流器
- `golang.org/x/time/rate`
- 基于令牌桶实现

```go
type Limiter struct {
	mu     sync.Mutex
	limit  Limit
	burst  int
	tokens float64
	// last is the last time the limiter's tokens field was updated
	last time.Time
	// lastEvent is the latest time of a rate-limited event (past or future)
	lastEvent time.Time
}
```

#### 初始化
- `limiter := rate.NewLimiter(10, 100);`
- 两个参数
    + 第一个参数每秒向桶中放令牌的个数
    + 令牌桶的容量，令牌最多的个数
- 还可以用`every`方法指定向桶中放置token的间隔
```go
limit := rate.Every(100 * time.Millisecond);
limiter := rate.NewLimiter(limit, 100);
```

#### 动态调整
- `SetLimit(Limit)` 改变放入 Token 的速率
- `SetBurst(int)` 改变 Token 桶大小

#### 使用
- 三类方法供程序消费 token
- 可以同步等待token生成，也可以没有token时返回token获取失败
- `Wait/WaitN`
- `Allow/AllowN`
- `Reserve/ReserveN`

#### Wait/WaitN
- Wait 相当于 WaitN(ctx, 1)
- 如果此时桶内 Token 数组不足 (小于 N)， Wait 方法将会阻塞一段时间，直至 Token 满足条件
- 如果充足则直接返回
- 可以设置 context 的 Deadline 或者 Timeout，来决定此次 Wait 的最长时间

#### Allow/AllowN
- Allow 实际上就是对 AllowN(time.Now(),1) 进行简化的函数
- AllowN 方法表示，截止到某一时刻，目前桶中数目是否至少为 n 个，满足则返回 true，同时从桶中消费 n 个 token。反之不消费桶中的Token，返回false
- 对应线上的使用场景是，如果请求速率超过限制，就直接丢弃超频后的请求

#### Reserve/ReserveN
- Reserve 相当于 ReserveN(time.Now(), 1)。
- ReserveN 的用法就相对来说复杂一些，当调用完成后，无论 Token 是否充足，都会返回一个 *Reservation 对象
- 可以调用该对象的Delay()方法，该方法返回的参数类型为time.Duration，反映了需要等待的时间，必须等到等待时间之后，才能进行接下来的工作
- 如果不想等待，可以调用Cancel()方法，该方法会将 Token 归还

#### 主要逻辑代码
```go
// reserveN is a helper method for AllowN, ReserveN, and WaitN.
// maxFutureReserve specifies the maximum reservation wait duration allowed.
// reserveN returns Reservation, not *Reservation, to avoid allocation in AllowN and WaitN.
func (lim *Limiter) reserveN(now time.Time, n int, maxFutureReserve time.Duration) Reservation {
	lim.mu.Lock()
	defer lim.mu.Unlock()

    // Inf 一个特别大的值，产生令牌的速率最大，代表一直有令牌
	if lim.limit == Inf {
		return Reservation{
			ok:        true,
			lim:       lim,
			tokens:    n,
			timeToAct: now,
		}
        // 不产生令牌，桶内的用光就没有了
	} else if lim.limit == 0 {
		var ok bool
		if lim.burst >= n {
			ok = true
			lim.burst -= n
		}
		return Reservation{
			ok:        ok,
			lim:       lim,
			tokens:    lim.burst,
			timeToAct: now,
		}
	}

    // 运行检查看是不是需要生成令牌，和limit生成令牌的时间
    // now 就是传进去的时间
    // last 如果为now，本轮没有生成令牌，否则生成新令牌了
    // tokens 本轮令牌总数
	now, last, tokens := lim.advance(now)

	// Calculate the remaining number of tokens resulting from the request.
    // 扣除需要使用的令牌
	tokens -= float64(n)

	// Calculate the wait duration
    // 根据令牌数机选需要等待时间
	var waitDuration time.Duration
	if tokens < 0 {
		waitDuration = lim.limit.durationFromTokens(-tokens)
	}

	// Decide result
    // 本轮是不是能拿到令牌
	ok := n <= lim.burst && waitDuration <= maxFutureReserve

	// Prepare reservation
	r := Reservation{
		ok:    ok,
		lim:   lim,
		limit: lim.limit,
	}
	if ok {
		r.tokens = n
		r.timeToAct = now.Add(waitDuration)
	}

	// Update state
	if ok {
		lim.last = now
		lim.tokens = tokens
		lim.lastEvent = r.timeToAct
	} else {
		lim.last = last
	}

	return r
}

// advance calculates and returns an updated state for lim resulting from the passage of time.
// lim is not changed.
// advance requires that lim.mu is held.
func (lim *Limiter) advance(now time.Time) (newNow time.Time, newLast time.Time, newTokens float64) {
	last := lim.last
	if now.Before(last) {
		last = now
	}

	// Calculate the new number of tokens, due to time that passed.
	elapsed := now.Sub(last)
	delta := lim.limit.tokensFromDuration(elapsed)
	tokens := lim.tokens + delta
	if burst := float64(lim.burst); tokens > burst {
		tokens = burst
	}
	return now, last, tokens
}

// durationFromTokens is a unit conversion function from the number of tokens to the duration
// of time it takes to accumulate them at a rate of limit tokens per second.
func (limit Limit) durationFromTokens(tokens float64) time.Duration {
	if limit <= 0 {
		return InfDuration
	}
	seconds := tokens / float64(limit)
	return time.Duration(float64(time.Second) * seconds)
}

// tokensFromDuration is a unit conversion function from a time duration to the number of tokens
// which could be accumulated during that duration at a rate of limit tokens per second.
func (limit Limit) tokensFromDuration(d time.Duration) float64 {
	if limit <= 0 {
		return 0
	}
	return d.Seconds() * float64(limit)
}
```


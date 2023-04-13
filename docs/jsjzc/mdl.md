### 示意图
![](http://image.heysq.com/wiki/jsjzc/mendianlu.jpeg)

### 半加器
- 一个异或门实现加法
- 一个与门判断是不是需要进位
- 两个门电路打包到一起的电路叫半加器
![](http://image.heysq.com/wiki/jsjzc/banjiaqi.jpeg)

### 全加器
- 两个半加器和一个或门组成全加器
- 第一个半加器，用和个位的加法一样的方式，得到是否进位 X 和对应的二个数加和后的结果 Y，这样两个输出。
- 把这个加和后的结果 Y，和个位数相加后输出的进位信息 U，再连接到一个半加器上，就会再拿到一个是否进位的信号 V 和对应的加和后的结果 W
![](http://image.heysq.com/wiki/jsjzc/quanjiaqi.jpeg)

#### 加法溢出
- 对于这个全加器，在个位，只需要用一个半加器，或者让全加器的进位输入始终是 0。因为个位没有来自更右侧的进位。
- 最左侧的一位输出的进位信号，表示的并不是再进一位，而是表示加法是否溢出了

#### 加法器加速-超前进位加法器
- 通过给加法器增加了一个不是十分复杂的逻辑电路来实现
- 通过预算出进位信息来达到减少延时的功能

### 乘法器
- 二进制乘法列式计算
![](http://image.heysq.com/wiki/jsjzc/chengfa.jpeg)
- 实际的乘法，就退化成了位移和加法
- 通过cpu的时钟周期控制每次加法进位和位移顺序
![](http://image.heysq.com/wiki/jsjzc/chengfashiyi.jpeg)
- 一个加法器、一个可以左移一位的电路和一个右移一位的电路
![](http://image.heysq.com/wiki/jsjzc/chengfaqi.jpeg)

#### 乘法器加速
- 并行计算
![](http://image.heysq.com/wiki/jsjzc/chengfajiasu.jpeg)
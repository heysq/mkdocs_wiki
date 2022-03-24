### CISC 复杂指令集
- Complex Instruction Set Computing
- 直接在硬件层面就能执行复杂的指令
- 优化执行的指令数，减少CPU的执行时间

### RISC 复杂指令集
- Reduced Instruction Set Computing
- 只使用常用的20%的指令
- 将复杂的指令用常用的指令组合替代
- 优化单个指令的执行时间，提升一个时钟周期内执行的指令数
- CPU电路简单，通用寄存器数量较多，更好的进行分支预测

> AMD，趁着 Intel 研发[安腾](https://wiki.heysq.com/jsjzc/cpu%E5%8A%A0%E9%80%9F/#vliw)的时候，推出了兼容 32 位 x86 指令集的 64 位架构，也就是现在常看到的 amd64

![](/images/jsjzc/sisc_risc.jpeg)

### 微指令
- Micro-Instructions/Micro-Ops
- intel借鉴RISC处理器的设计思想，让CISC指令运行在RISC处理器中
- 编译出的机器码和汇编代码并没有变化
- 指令译码器在翻译指令时，翻译出的不再是一条指令，而是几个RISC风格的微指令
- 翻译出的微指令被放到微指令缓冲区中，然后从缓冲区发送到超标量，并且是乱序的精简指令流水线架构

#### 微指令困难
- 译码器由原来的翻译指令变成翻译RISC微指令，增加电路和翻译难度
- 复杂的电路和更长的译码时间，导致翻译性能下降

#### 解决
- 增加L0 cache
- 保存指令译码器把CISC指令翻译成RISC微指令的结果
- 大部分情况下都可以在缓存中直接取到翻译后的结果


### ARM
- Advanced RISC Machines
- 基于RISC架构
- 主频比Intel x86更低，晶体管更少，高速缓存更小，乱序执行能力更弱，但是减低了功耗
- 低价，没有进行行业垄断，只进行CPU设计
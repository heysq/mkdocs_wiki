```c
#include <stdio.h>

int static add(int a, int b)
{
    return a + b;
}

int main()
{
    int x = 5;
    int y = 10;
    int u = add(x,  y);
}
```
```c

chengxuzhan.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <add>:
#include <stdio.h>

int static add(int a, int b)
{
   0:   f3 0f 1e fa             endbr64 
   4:   55                      push   rbp
   5:   48 89 e5                mov    rbp,rsp
   8:   89 7d fc                mov    DWORD PTR [rbp-0x4],edi
   b:   89 75 f8                mov    DWORD PTR [rbp-0x8],esi
    return a + b;
   e:   8b 55 fc                mov    edx,DWORD PTR [rbp-0x4]
  11:   8b 45 f8                mov    eax,DWORD PTR [rbp-0x8]
  14:   01 d0                   add    eax,edx
}
  16:   5d                      pop    rbp
  17:   c3                      ret    

0000000000000018 <main>:

int main()
{
  18:   f3 0f 1e fa             endbr64 
  1c:   55                      push   rbp
  1d:   48 89 e5                mov    rbp,rsp
  20:   48 83 ec 10             sub    rsp,0x10
    int x = 5;
  24:   c7 45 f4 05 00 00 00    mov    DWORD PTR [rbp-0xc],0x5
    int y = 10;
  2b:   c7 45 f8 0a 00 00 00    mov    DWORD PTR [rbp-0x8],0xa
    int u = add(x,  y);
  32:   8b 55 f8                mov    edx,DWORD PTR [rbp-0x8]
  35:   8b 45 f4                mov    eax,DWORD PTR [rbp-0xc]
  38:   89 d6                   mov    esi,edx
  3a:   89 c7                   mov    edi,eax
  3c:   e8 bf ff ff ff          call   0 <add>
  41:   89 45 fc                mov    DWORD PTR [rbp-0x4],eax
  44:   b8 00 00 00 00          mov    eax,0x0
  49:   c9                      leave  
  4a:   c3                      ret    
```

### add函数
- push指令和mov指令：压栈操作
- pop 指令和ret指令: 出栈操作

### 乒乓球桶举例栈
![](http://image.heysq.com/wiki/jsjzc/chengxuzhan.jpg)

### 实际程序
- 实际的程序栈布局，顶和底与我们的乒乓球桶相比是倒过来的。底在最上面，顶在最下面
- 这样的布局是因为栈底的内存地址是在一开始就固定的。而一层层压栈之后，栈顶的内存地址是在逐渐变小而不是变大
![](http://image.heysq.com/wiki/jsjzc/chengxuzhanshiji.jpg)

### 函数内联
- 已知不会有嵌套调用函数的情况下，将`call`指令替换为调用函数的地址
- 内联带来的优化是，CPU 需要执行的指令数变少了，根据地址跳转的过程不需要了，压栈和出栈的过程也不用了
- 内联意味着，我们把可以复用的程序指令在调用它的地方完全展开了。如果一个函数在很多地方都被调用了，那么就会展开很多次，整个程序占用的空间就会变大

> 这样没有调用其他函数，只会被调用的函数，一般称之为叶子函数（或叶子过程）

#### 举例
```c
#include <stdio.h>
#include <time.h>
#include <stdlib.h>
 
int static add(int a, int b)
{
    return a+b;
}
 
int main()
{
    srand(time(NULL));
    int x = rand() % 5;
    int y = rand() % 10;
    int u = add(x, y);
    printf("u = %d\n", u);
}
```

#### 编译结果
- `call`被转换成了`add`
```c
Disassembly of section .text:

0000000000000000 <main>:
{
    return a+b;
}
 
int main()
{
   0:   f3 0f 1e fa             endbr64 
   4:   53                      push   rbx
    srand(time(NULL));
   5:   bf 00 00 00 00          mov    edi,0x0
   a:   e8 00 00 00 00          call   f <main+0xf>
   f:   48 89 c7                mov    rdi,rax
  12:   e8 00 00 00 00          call   17 <main+0x17>
    int x = rand() % 5;
  17:   e8 00 00 00 00          call   1c <main+0x1c>
  1c:   89 c3                   mov    ebx,eax
    int y = rand() % 10;
  1e:   e8 00 00 00 00          call   23 <main+0x23>
  23:   89 c2                   mov    edx,eax
    int x = rand() % 5;
  25:   48 63 cb                movsxd rcx,ebx
  28:   48 69 c9 67 66 66 66    imul   rcx,rcx,0x66666667
  2f:   48 c1 f9 21             sar    rcx,0x21
  33:   89 d8                   mov    eax,ebx
  35:   c1 f8 1f                sar    eax,0x1f
  38:   29 c1                   sub    ecx,eax
  3a:   8d 04 89                lea    eax,[rcx+rcx*4]
  3d:   29 c3                   sub    ebx,eax
    int y = rand() % 10;
  3f:   48 63 ca                movsxd rcx,edx
  42:   48 69 c9 67 66 66 66    imul   rcx,rcx,0x66666667
  49:   48 c1 f9 22             sar    rcx,0x22
  4d:   89 d0                   mov    eax,edx
  4f:   c1 f8 1f                sar    eax,0x1f
  52:   29 c1                   sub    ecx,eax
  54:   8d 04 89                lea    eax,[rcx+rcx*4]
  // 直接转换成了add
  57:   01 c0                   add    eax,eax
  59:   29 c2                   sub    edx,eax
    return a+b;
  5b:   01 da                   add    edx,ebx
}

__fortify_function int
printf (const char *__restrict __fmt, ...)
{
  return __printf_chk (__USE_FORTIFY_LEVEL - 1, __fmt, __va_arg_pack ());
  5d:   48 8d 35 00 00 00 00    lea    rsi,[rip+0x0]        # 64 <main+0x64>
  64:   bf 01 00 00 00          mov    edi,0x1
  69:   b8 00 00 00 00          mov    eax,0x0
  6e:   e8 00 00 00 00          call   73 <main+0x73>
    int u = add(x, y);
    printf("u = %d\n", u);
  73:   b8 00 00 00 00          mov    eax,0x0
  78:   5b                      pop    rbx
  79:   c3                      ret
```
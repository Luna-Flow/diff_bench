# DzmingLi decimal 与 floating GDA 设计及性能报告

## 实验契约

两种实现接收完全相同的 coefficient-and-scale fixture。`arithmetic_only`
只计时公开运算；`full_path` 还包含两个规范字符串的解析。校验、规范化、校准和报告
均位于计时区间外。除法只使用可精确终止的除数。仅当双方都通过独立 exact-finite
`BigInt` oracle 时才计算配对性能。

## 正确性

scaling corpus 共执行 1,476 次校验。floating GDA 的 738 次全部通过；DzmingLi
通过 630 次、失败 108 次。加、减、乘、除从 4,096 位 coefficient 开始失败，
compare 至 20,000 位仍正确。

官方 GDA 审计覆盖 23 个算术/base 文件、17,651 条合法用例，floating GDA 全部通过。
DzmingLi 的全部共享算术、比较和 `apply` 通过，但 `toSci` 有 329 条失败，原因是格式化没有应用当前 precision
和 rounding。官方有限输入最大只有 64 位 coefficient，因此 decTest 不能替代大数 oracle。

位数性能层覆盖 19 项精确操作，新增 14 项运行到 1,024 位。`exp/ln/log10` 只做
decTest 正确性；用 0/1 恒等式计时不能代表算法，一般结果还需要另一套独立超越函数 oracle。

DzmingLi 的 `digit_count` 在有符号 `Int` 中计算 `bit_length * 30103`。当前 native
目标约在 21,475 位 coefficient 时有溢出风险；乘法、FMA product、平方和二次幂可能
把结果位数翻倍，因此约 10,738 位输入就可能跨线。实测乘法 10,000 位和非乘法
20,000 位可完成，32,768/65,536 位会 abort。这些是分析及实测边界，不是统一的精确必崩点。

## 性能

1–64 位时 DzmingLi 全面领先；到 256 位，两种 timing scope 下的五种操作都转为
floating GDA 领先。1,024 位且双方仍正确时，floating GDA 根据操作和 scope 约快
`3.4–33.8×`。更大的算术规模因 DzmingLi 结果错误，只保留已验证的 GDA latency，
不计算 speedup。

## 边界

数据来自 Apple M4、native release、CPU 频率未控制的一次运行。语料只有三个确定性
scale profile，除法使用较小的终止除数；结论用于回归与实现分析，不是通用排名。

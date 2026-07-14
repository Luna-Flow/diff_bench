# 运行与复现教程

## 运行基准

在仓库根目录执行：

```sh
moon run --release src/floating_vs_decmial_x/bench --target native
```

若只想比较 X 常用的 1、4、8、16、18、28 位系数，执行：

```sh
moon run --release src/floating_vs_decmial_x/bench_common --target native
```

## 记录环境

已知主机信息可通过 `MARE_CPU`、`MARE_OS`、`MARE_BUILD_MODE` 等 `MARE_*` 环境变量传入。未提供的信息会记录为 `unknown` 或 `unspecified`，不会从源码推断其他机器的环境。

## 阅读结果

- `arithmetic_only`：每个实现只执行一次公开算术操作。
- `semantic_equivalent_pipeline`：包含复现 X 结果策略所需的完整公开 API 流程。
- `artifacts/mare_mark_performance.html`：宽范围系数规模报告。
- `artifacts/mare_mark_common_digits_performance.html`：常见位数报告。

不同 MoonBit target 的结果必须分开运行和分析，不能直接合并。

# `floating_vs_decmial_x` API

## 定位

本包是仓库内的差分测试与性能基准，不是生产运行时库。它只保留在 GitHub 仓库中用于参考、复现和回归检查，不发布到 Mooncakes。

## 运行入口

```sh
moon run --release src/floating_vs_decmial_x/bench --target native
moon run --release src/floating_vs_decmial_x/bench_common --target native
```

`bench` 测量 1、4、16、64、256、1024、4096 位系数；`bench_common` 测量 1、4、8、16、18、28 位系数。

## 主要导出项

- `DecimalValue`：中立的系数与十进制 scale 表示。
- `DecimalSemantics`：`ExactOverlap` 与 `XCompatible` 语义组。
- `Operation`：加、减、乘、除、比较等操作。
- `prepare_fixture`：在计时区间外构造双方实现的公共 fixture。
- `working_precision`：按操作和语义计算 GDA 所需工作精度。
- `canonical_observation`：将两种实现的结果转换到统一比较边界。

基准输出包括验证、校准、原始观测、汇总和配对比较 JSONL 记录，并生成 `artifacts/` 下的 HTML 报告。

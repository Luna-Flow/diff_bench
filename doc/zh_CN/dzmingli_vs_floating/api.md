# 基准 API 与运行入口

`dzmingli_vs_floating` 使用同一组中立十进制 fixture，对比
`DzmingLi/decimal@0.2.2` 与 `Luna-Flow/floating/decimal_gda@0.7.1`。

可扩展性能交集共 19 项：基础四则、整数除法、余数、整数幂、FMA、完平方根、
正负号/绝对值、quantize、rescale、scaleb、reduce、两种 to-integral 与 compare。
官方 decTest 另外覆盖双方共有的 `exp`、`ln`、`log10` 语义。

- `src/dzmingli_vs_floating/bench`：常规规模至 10,000 位，非乘法压力规模至 20,000 位。
- `src/dzmingli_vs_floating/bench_common`：1、4、8、16、18、28 位。
- `tools/run_dzmingli_dectest_audit.sh`：固定版本的官方 GDA decTest 审计。

runner 输出 validation、calibration、observation、summary、comparison JSONL，
并在 `artifacts/` 下生成自包含 HTML 报告。

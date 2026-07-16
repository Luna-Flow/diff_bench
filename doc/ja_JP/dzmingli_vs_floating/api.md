# ベンチマーク API と実行入口

`dzmingli_vs_floating` は同一の中立 decimal fixture を用いて
`DzmingLi/decimal@0.2.2` と `Luna-Flow/floating/decimal_gda@0.7.1` を比較します。

scalable な性能交差面は、四則演算、整数除算、剰余、整数 power、FMA、完全平方根、
単項 plus/minus/abs、quantize、rescale、scaleb、reduce、二つの to-integral、compare
の 19 操作です。公式 decTest は共通の `exp`、`ln`、`log10` も検証します。

- `src/dzmingli_vs_floating/bench`: 通常サイズは 10,000 桁、乗算以外の stress は 20,000 桁まで。
- `src/dzmingli_vs_floating/bench_common`: 1、4、8、16、18、28 桁。
- `tools/run_dzmingli_dectest_audit.sh`: 固定された公式 GDA decTest 監査。

runner は JSONL の validation、calibration、observation、summary、comparison と、
`artifacts/` 配下の自己完結 HTML レポートを生成します。

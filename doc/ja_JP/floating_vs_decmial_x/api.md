# `floating_vs_decmial_x` API

本パッケージは差分テスト・性能ベンチマーク用で、本番ランタイムではありません。再現と参考のため GitHub にのみ保持し、Mooncakes には公開しません。

規模測定は `moon run --release src/floating_vs_decmial_x/bench --target native`、共通桁測定（1、4、8、16、18、28 桁）は `bench_common` で実行します。中立 fixture、`DecimalSemantics`（`ExactOverlap`/`XCompatible`）、操作、作業精度、結果正規化を提供し、JSONL と `artifacts/` の HTML レポートを出力します。

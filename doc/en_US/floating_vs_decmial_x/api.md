# `floating_vs_decmial_x` API

This is a differential-testing and performance benchmark, not a production runtime library. It is kept on GitHub for reproduction and reference and is not published to Mooncakes.

Run `moon run --release src/floating_vs_decmial_x/bench --target native` for scaling data, or `moon run --release src/floating_vs_decmial_x/bench_common --target native` for 1, 4, 8, 16, 18, and 28 coefficient digits. The package exposes neutral decimal fixtures, `DecimalSemantics` (`ExactOverlap`/`XCompatible`), operations, working-precision helpers, and canonical observations. It emits JSONL validation/calibration/observation/summary/comparison records and HTML reports under `artifacts/`.

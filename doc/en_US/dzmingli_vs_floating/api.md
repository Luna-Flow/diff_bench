# Benchmark API and Entrypoints

`dzmingli_vs_floating` compares `DzmingLi/decimal@0.2.2` and
`Luna-Flow/floating/decimal_gda@0.7.1` on shared neutral decimal fixtures.
The package exposes fixture generation, exact-finite `BigInt` reference
operations, adapters, Mare Mark execution, and report rendering.

The scalable overlap covers 19 operations: the four basic operations,
divide-integer, remainder, integer power, FMA, exact square root, unary
plus/minus/abs, quantize, rescale, scaleb, reduce, both to-integral variants,
and compare. Official decTest additionally covers shared `exp`, `ln`, and
`log10` semantics.

- `src/dzmingli_vs_floating/bench`: scaling run through 10,000 digits, plus
  non-multiplication stress through 20,000 digits.
- `src/dzmingli_vs_floating/bench_common`: 1, 4, 8, 16, 18, and 28 digits.
- `tools/run_dzmingli_dectest_audit.sh`: pinned official GDA decTest audit.

The runners emit validation, calibration, observation, summary, and comparison
JSONL records and write self-contained HTML reports under `artifacts/`.

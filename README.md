# diff_bench

Differential correctness and performance benchmarks for Luna-Flow MoonBit packages.

## Decimal X versus floating GDA

The `floating_vs_decmial_x` package compares:

- `moonbitlang/x/decimal@0.4.46`
- `Luna-Flow/floating/decimal_gda@0.6.1`

Both implementations consume the same neutral decimal fixtures. Mare Mark 0.2.0 performs validation
outside the timing path, calibrates each implementation, uses balanced execution order, retains
raw observations, and calculates paired performance comparisons.

Run the native scaling benchmark:

```sh
moon run --release src/floating_vs_decmial_x/bench --target native
```

Run the separate common-digit benchmark for 1, 4, 8, 16, 18, and 28-digit
coefficients:

```sh
moon run --release src/floating_vs_decmial_x/bench_common --target native
```

The common-digit runner writes
`artifacts/mare_mark_common_digits_performance.html` and does not overwrite the
scaling report.

For portable provenance, set the optional `MARE_*` environment overrides when
the host facts are known (for example, `MARE_CPU`, `MARE_OS`, and
`MARE_BUILD_MODE`). Missing host facts are recorded as `unknown` or
`unspecified`; they are never inferred from another machine's benchmark.

The command emits JSONL containing validation, calibration, observation, summary, and comparison
records. Results from different MoonBit targets must not be combined.

The native benchmark also writes `artifacts/mare_mark_performance.html` using Mare Mark's Plot IR
and self-contained HTML renderer. The existing dependency-free SVG plotting helper remains
available for side-by-side regression checks.

This repository is a GitHub-only benchmark and reference project. The
`floating_vs_decmial_x` package is not published to Mooncakes and is not intended
to be used as a downstream runtime dependency.

To save a run and render comparison plots:

```sh
python3 -m venv .venv
.venv/bin/pip install -r requirements-plot.txt
moon run --release src/floating_vs_decmial_x/bench --target native > /tmp/diff_bench_native.jsonl
.venv/bin/python scripts/plot_benchmark.py /tmp/diff_bench_native.jsonl artifacts/arithmetic_only.svg arithmetic_only
.venv/bin/python scripts/plot_benchmark.py /tmp/diff_bench_native.jsonl artifacts/semantic_equivalent_pipeline.svg semantic_equivalent_pipeline
```

The Matplotlib helper reads `comparison` JSONL records and writes SVG, PNG, or PDF. Each panel uses
a base-2 logarithmic coefficient-size axis and reports median microseconds per operation (`µs/op`).
The subtitle records the timing scope and paired sample count; lower values are faster.

## Development

```sh
just fmt
just check-all
just test
just ready
```

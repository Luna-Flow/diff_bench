# diff_bench

Differential correctness and performance benchmarks for Luna-Flow MoonBit packages.

## DzmingLi decimal versus floating GDA

The `dzmingli_vs_floating` package compares `DzmingLi/decimal@0.2.2` with
`Luna-Flow/floating/decimal_gda@0.6.1`. The benchmark deliberately pins the
deprecated DzmingLi release for historical comparison; its maintained successor
is `moonbit-community/decimal`.

Mare Mark validates both implementations against an exact `BigInt` oracle and
reports performance for two symmetric timing scopes: `arithmetic_only` measures
the public operation with operands prepared outside timing, while `full_path`
includes context-aware parsing and constructing both already-serialized operands
before that operation. Division
uses exact terminating inputs, and this comparison applies neither X-compatible
semantics nor fixed 28-digit quantization.

Run the native scaling benchmark, covering general 1–4,096-digit inputs, all
operations through 10,000 digits, and non-multiplication stress inputs through
20,000 coefficient digits. Every size uses three identical operand profiles and
60 paired confirmatory samples:

```sh
moon run --release src/dzmingli_vs_floating/bench --target native
```

Run the 1, 4, 8, 16, 18, and 28-digit benchmark:

```sh
moon run --release src/dzmingli_vs_floating/bench_common --target native
```

The runners write
`artifacts/mare_mark_dzmingli_vs_floating_performance.html` and
`artifacts/mare_mark_dzmingli_vs_floating_common_digits.html`, with matching
`extended.jsonl` and `common_digits.jsonl` raw records. See
`src/dzmingli_vs_floating/README.md` for the corpus and measurement contract,
and `src/dzmingli_vs_floating/BENCHMARK_RESULTS.md` for the recorded DzmingLi
correctness failures and large-input abort boundary.

The latest Apple M4 native run records 738/738 exact-finite validations passing
for floating GDA and 630/738 for DzmingLi. The separate 23-file official GDA
arithmetic audit finds 329 DzmingLi `toSci` failures; floating GDA passes all
17,651 legal rows.

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

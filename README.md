# diff_bench

Differential correctness and performance benchmarks for Luna-Flow MoonBit packages.

## Benchmark framework and publication artifacts

The repository has migrated both benchmark packages to the current pinned
`Luna-Flow/mare_mark@0.3.0` framework. Every run emits versioned `mmka_1`
JSONL, and the shared Python parser converts that data into `mmks_1` Plot IR.
Package-specific Matplotlib layouts then render a consistent set of publication
figures without recomputing benchmark statistics.

Each package keeps its raw records, self-contained HTML reports, Plot IR, and
figures in its own `artifacts/<package>/` directory. PNG is convenient for
quick previews and documents, PDF is suitable for distribution and archival,
and SVG remains editable for web or publication workflows. Keeping JSONL and
Plot IR beside those figures preserves the provenance needed to reproduce them.

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
moon run --release src/dzmingli_vs_floating/bench --target native \
  > artifacts/dzmingli_vs_floating/scaling.jsonl
```

Run the 1, 4, 8, 16, 18, and 28-digit benchmark:

```sh
moon run --release src/dzmingli_vs_floating/bench_common --target native \
  > artifacts/dzmingli_vs_floating/common_digits.jsonl
```

The runners write `scaling.html`, `common_digits.html`, and matching JSONL
records under `artifacts/dzmingli_vs_floating/`. The Python layouts add
`main.{png,pdf,svg}`, `supplementary.{png,pdf,svg}`, and their Plot IR JSON.
See
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

Both implementations consume the same neutral decimal fixtures. Mare Mark 0.3.0 performs validation
outside the timing path, calibrates each implementation, uses balanced execution order, retains
raw observations, and calculates paired performance comparisons.

Run the native scaling benchmark:

```sh
moon run --release src/floating_vs_decmial_x/bench --target native \
  > artifacts/floating_vs_decmial_x/scaling.jsonl
```

Run the separate common-digit benchmark for 1, 4, 8, 16, 18, and 28-digit
coefficients:

```sh
moon run --release src/floating_vs_decmial_x/bench_common --target native \
  > artifacts/floating_vs_decmial_x/common_digits.jsonl
```

The runners write `scaling.html`, `common_digits.html`, and matching JSONL
records under `artifacts/floating_vs_decmial_x/`; the Python layout adds
`main.{png,pdf,svg}` and `main.ir.json`.

For portable provenance, set the optional `MARE_*` environment overrides when
the host facts are known (for example, `MARE_CPU`, `MARE_OS`, and
`MARE_BUILD_MODE`). Missing host facts are recorded as `unknown` or
`unspecified`; they are never inferred from another machine's benchmark.

The command emits JSONL containing validation, calibration, observation, summary, and comparison
records. Results from different MoonBit targets must not be combined.

The native benchmark also writes `artifacts/floating_vs_decmial_x/scaling.html`
using Mare Mark's Plot IR and self-contained HTML renderer.

This repository is a GitHub-only benchmark and reference project. The
`floating_vs_decmial_x` package is not published to Mooncakes and is not intended
to be used as a downstream runtime dependency.

To render the unified Matplotlib figures from the recorded scaling runs:

```sh
python3 -m venv .venv
.venv/bin/pip install -r requirements-plot.txt
.venv/bin/python tools/plot_dzmingli_benchmark.py
.venv/bin/python tools/plot_dzmingli_supplementary_benchmark.py
.venv/bin/python tools/layout_x_decimal.py
```

All layouts consume the shared Plot IR model and write PNG, PDF, and SVG from
the same data. Each panel uses a base-2 logarithmic coefficient-size axis and
reports median microseconds per operation (`µs/op`); lower values are faster.

## Development

```sh
just fmt
just check-all
just test
just ready
```

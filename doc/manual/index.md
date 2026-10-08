# diff_bench

This manual documents version `0.1.0` of `Luna-Flow/diff_bench` as it stands on
the current branch.

## Overview

`diff_bench` holds differential correctness and performance benchmarks for
Luna-Flow MoonBit packages. Each benchmark runs two decimal libraries on the
same inputs, checks both against an independent `BigInt` oracle, and measures
them with [Mare Mark](https://lunaflow.cn/en/mare_mark/) only where the
results are right. The subject on the Luna-Flow side is
[floating](https://lunaflow.cn/en/floating/)'s `decimal_gda` package.

Every input is materialized from a fixed seed into a neutral decimal
$(c, s) \mapsto c \cdot 10^{-s}$, converted to each library outside timing,
and computed at a precision that provably holds the exact result. Results are
canonicalized and compared with the oracle by exact equality. Timed samples of
the two libraries are paired by dataset, repetition and block, and summarized
by medians.

## Install

The repository is a GitHub-only reference project. It is not published on
mooncakes and is not meant as a runtime dependency, so there is no
`moon add` step. Clone it and work inside the module:

```bash
git clone https://github.com/Luna-Flow/diff_bench.git
cd diff_bench
moon test --target native
```

A package inside the module imports a benchmark in its `moon.pkg`:

```moonbit nocheck
import {
  "Luna-Flow/diff_bench/dzmingli_vs_floating",
}
```

The code needs the MoonBit toolchain 0.10 or later (`moonc` ≥ 0.10) with the
`moon.mod` and `moon.pkg` manifests. The library packages build on every
target; the executables and the asynchronous Mare Mark runs need `native`
(the async runner also works on `js`). Published measurements are native
release runs.

## Pages

The module has seven packages: the root package, documented as `core`, two
benchmark libraries and one scaling and one common-digit executable for each.

| Part | Tutorial | API | Design |
| --- | --- | --- | --- |
| `core`: the root package, a template placeholder | [tutorial](tutorial/core.md) | [API](api/core.md) | [design](design/core.md) |
| `dzmingli_vs_floating`: `DzmingLi/decimal@0.2.2` versus floating GDA, exact oracle, 19 operations | [tutorial](tutorial/dzmingli_vs_floating.md) | [API](api/dzmingli_vs_floating.md) | [design](design/dzmingli_vs_floating.md) |
| `dzmingli_vs_floating/bench`: scaling executable, 1 to 20,000 digits | [tutorial](tutorial/dzmingli_vs_floating/bench.md) | [API](api/dzmingli_vs_floating/bench.md) | [design](design/dzmingli_vs_floating/bench.md) |
| `dzmingli_vs_floating/bench_common`: common-digit executable, 1 to 28 digits | [tutorial](tutorial/dzmingli_vs_floating/bench_common.md) | [API](api/dzmingli_vs_floating/bench_common.md) | [design](design/dzmingli_vs_floating/bench_common.md) |
| `floating_vs_decmial_x`: `moonbitlang/x/decimal` versus floating GDA, two semantic groups | [tutorial](tutorial/floating_vs_decmial_x.md) | [API](api/floating_vs_decmial_x.md) | [design](design/floating_vs_decmial_x.md) |
| `floating_vs_decmial_x/bench`: scaling executable, 1 to 4,096 digits | [tutorial](tutorial/floating_vs_decmial_x/bench.md) | [API](api/floating_vs_decmial_x/bench.md) | [design](design/floating_vs_decmial_x/bench.md) |
| `floating_vs_decmial_x/bench_common`: common-digit executable, 1 to 28 digits | [tutorial](tutorial/floating_vs_decmial_x/bench_common.md) | [API](api/floating_vs_decmial_x/bench_common.md) | [design](design/floating_vs_decmial_x/bench_common.md) |

The performance chapter reports the measured results of both comparisons:
[DzmingLi versus GDA](performance/dzmingli_vs_floating.md) and
[X versus GDA](performance/floating_vs_decmial_x.md). The
[contribution guidelines](contributing.md) cover style, tests and the
documentation workflow.

## Exported items

Both benchmark libraries export the same skeleton, with library-specific
adapters:

- Neutral decimal model: `DecimalValue`, `parse_decimal_value`, `normalize`,
  `canonical_string`, and exact `add`, `subtract`, `multiply`, `compare`
- Oracle: `oracle_operation` (and `oracle_operation3` for FMA), `oracle_divide`,
  `oracle_multiply`, `OracleResult`
- Cases and fixtures: `Operation`, `generate_decimal`, `generate_cases`,
  `working_precision`, `prepare_fixture`, `run_gda` and `run_dz` or `run_x`,
  `canonical_observation`
- Mare Mark integration: `run_mare_benchmark`, `default_benchmark_protocol`,
  `smoke_protocol`, `expand_digit_scales`, `PerformanceResult` and the report
  writers `mare_performance_report_html` and `mare_performance_report_document`

## Artifacts and tools

Raw JSONL records, HTML reports, Plot IR and the PNG, PDF and SVG figures are
kept under `artifacts/<package>/`, outside the manual. The `tools/` directory
holds the Python figure layouts (`plot_dzmingli_benchmark.py`,
`plot_dzmingli_supplementary_benchmark.py`, `layout_x_decimal.py`, sharing
`mare_plot_ir.py`) and the official decTest audit
(`run_dzmingli_dectest_audit.sh`).

## Where to read next

- New to the package: read the
  [`dzmingli_vs_floating` tutorial](tutorial/dzmingli_vs_floating.md). It
  checks one division against the oracle in a dozen lines and then reproduces
  the published run.
- Reading the results: start with the performance pages, then the design
  pages for what the numbers mean: the
  [precision contract](design/dzmingli_vs_floating.md#precision-contract), the
  [paired statistics](design/dzmingli_vs_floating.md#paired-statistics) and the
  [semantic groups](design/floating_vs_decmial_x.md#two-semantic-groups) of the
  X comparison.
- Contributing: read both design pages, then the
  [contribution guidelines](contributing.md). A new operation needs an oracle
  rule, a precision bound with a proof, and a test before it is timed.

## Validation

Run the release checks from the repository root:

```bash
moon check --target all
moon test --target native
```

> [!WARNING]
> On `native` and `js` one test fails:
> `division precision follows the requested semantic contract` expects `4097`,
> a value recorded on `wasm-gc`, where `BigInt::from_string` in
> `moonbitlang/core` misparses long inputs. The correct value is `4099`; see
> the [`floating_vs_decmial_x` design](design/floating_vs_decmial_x.md#boundaries).

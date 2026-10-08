# diff_bench

`diff_bench` holds differential correctness and performance benchmarks for
Luna-Flow MoonBit packages. Each benchmark runs two decimal libraries on the
same inputs, checks both against an independent `BigInt` oracle, and measures
them with [Mare Mark](https://lunaflow.cn/en/mare_mark/) only where the
results are right. The subject on the Luna-Flow side is
[floating](https://lunaflow.cn/en/floating/)'s `decimal_gda` package.

The repository is a GitHub-only reference project. It is not published on
mooncakes and is not meant as a runtime dependency.

## Packages

| Package | Role | API | Tutorial | Design |
| --- | --- | --- | --- | --- |
| `diff_bench` (root) | template placeholder | [API](api/core.md) | [tutorial](tutorial/core.md) | [design](design/core.md) |
| `dzmingli_vs_floating` | `DzmingLi/decimal@0.2.2` versus floating GDA, exact oracle, 19 operations | [API](api/dzmingli_vs_floating.md) | [tutorial](tutorial/dzmingli_vs_floating.md) | [design](design/dzmingli_vs_floating.md) |
| `dzmingli_vs_floating/bench` | scaling executable, 1 to 20,000 digits | [API](api/dzmingli_vs_floating/bench.md) | [tutorial](tutorial/dzmingli_vs_floating/bench.md) | [design](design/dzmingli_vs_floating/bench.md) |
| `dzmingli_vs_floating/bench_common` | common-digit executable, 1 to 28 digits | [API](api/dzmingli_vs_floating/bench_common.md) | [tutorial](tutorial/dzmingli_vs_floating/bench_common.md) | [design](design/dzmingli_vs_floating/bench_common.md) |
| `floating_vs_decmial_x` | `moonbitlang/x/decimal` versus floating GDA, two semantic groups | [API](api/floating_vs_decmial_x.md) | [tutorial](tutorial/floating_vs_decmial_x.md) | [design](design/floating_vs_decmial_x.md) |
| `floating_vs_decmial_x/bench` | scaling executable, 1 to 4,096 digits | [API](api/floating_vs_decmial_x/bench.md) | [tutorial](tutorial/floating_vs_decmial_x/bench.md) | [design](design/floating_vs_decmial_x/bench.md) |
| `floating_vs_decmial_x/bench_common` | common-digit executable, 1 to 28 digits | [API](api/floating_vs_decmial_x/bench_common.md) | [tutorial](tutorial/floating_vs_decmial_x/bench_common.md) | [design](design/floating_vs_decmial_x/bench_common.md) |

The [performance chapter](performance/dzmingli_vs_floating.md) reports the
measured results of both comparisons
([DzmingLi](performance/dzmingli_vs_floating.md),
[X](performance/floating_vs_decmial_x.md)).

## Reading paths

**First time here.** Read the
[`dzmingli_vs_floating` tutorial](tutorial/dzmingli_vs_floating.md): it
checks one division against the oracle in a dozen lines and then reproduces the
published run.

**Reading the results.** Start with the performance pages, then the design
pages for what the numbers mean: the
[precision contract](design/dzmingli_vs_floating.md#precision-contract), the
[paired statistics](design/dzmingli_vs_floating.md#paired-statistics) and the
[semantic groups](design/floating_vs_decmial_x.md#two-semantic-groups) of the X
comparison.

**Contributing.** Read both design pages, then the
[contribution guidelines](contributing.md). A new operation needs an oracle
rule, a precision bound with a proof, and a test before it is timed.

## Method in one paragraph

Every input is materialized from a fixed seed into a neutral decimal
$(c, s) \mapsto c \cdot 10^{-s}$, converted to each library outside timing,
and computed at a precision that provably holds the exact result. Results are
canonicalized and compared with the oracle by exact equality. Timed samples of
the two libraries are paired by dataset, repetition and block, and summarized
by medians.

## Artifacts and tools

Raw JSONL records, HTML reports, Plot IR and the PNG, PDF and SVG figures are
kept under `artifacts/<package>/`, outside the manual. The `tools/` directory
holds the Python figure layouts (`plot_dzmingli_benchmark.py`,
`plot_dzmingli_supplementary_benchmark.py`, `layout_x_decimal.py`, sharing
`mare_plot_ir.py`) and the official decTest audit
(`run_dzmingli_dectest_audit.sh`).

## Toolchain

The code targets MoonBit `moonc` 0.10 or later with the `moon.mod` and
`moon.pkg` manifests. The library packages build on every target; the
executables and the asynchronous Mare Mark runs need `native` (the async
runner also works on `js`). Published measurements are native release runs.

```sh
moon check --target all
moon test --target native
```

On `native` and `js` one test fails:
`division precision follows the requested semantic contract` expects `4097`,
a value recorded on `wasm-gc`, where `BigInt::from_string` in
`moonbitlang/core` misparses long inputs. The correct value is `4099`; see the
[`floating_vs_decmial_x` design](design/floating_vs_decmial_x.md#boundaries).

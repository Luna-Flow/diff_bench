# floating_vs_decmial_x/bench_common API

## Purpose

`Luna-Flow/diff_bench/floating_vs_decmial_x/bench_common` is an executable package. It has no public
items; its interface is the command line and the files it writes. It uses the
library package [`floating_vs_decmial_x`](../floating_vs_decmial_x.md).

## Importing

An executable package cannot be imported. Run it with `moon run` from the
repository root, as shown under [Command](#command); to reuse its pieces,
import the library package instead.

## Command

```sh
moon run --release src/floating_vs_decmial_x/bench_common --target native
```

The executable takes no arguments. The replay commands recorded in the JSONL
append operation, size and implementation arguments; the executable ignores
them and reruns the whole experiment.

## Experiments

It runs the same two experiments as the [scaling executable](bench.md), at 1,
4, 8, 16, 18 and 28 coefficient digits, three datasets per size.

## Output

- Standard output: the Mare Mark JSONL of every experiment (validation,
  calibration, observation, summary records), each followed by one
  `"comparison"` record per `PerformanceResult`.
- `artifacts/floating_vs_decmial_x/common_digits.html`: a self-contained HTML report written with
  `mare_performance_report_html`. The directories are created when missing.

## Exit status

The executable aborts with `common-digits decimal differential validation failed` when any validation failed, after the
report has been written. A complete run without failures exits normally.

## Targets

`main.mbt` is compiled for `native` only. On `js`, `wasm`, `wasm-gc` and
`llvm` the package builds `main_unimplemented.mbt`, which prints that the
runner requires `native` and exits.

# dzmingli_vs_floating/bench_common API

`Luna-Flow/diff_bench/dzmingli_vs_floating/bench_common` is an executable package. It has no public
items; its interface is the command line and the files it writes. It uses the
library package [`dzmingli_vs_floating`](../dzmingli_vs_floating.md).

## Command

```sh
moon run --release src/dzmingli_vs_floating/bench_common --target native
```

The executable takes no arguments. The replay commands recorded in the JSONL
append operation, size and implementation arguments; the executable ignores
them and reruns the whole experiment.

## Experiments

It runs `run_mare_benchmark` twice with `default_benchmark_protocol()` and
seed `0xDEC1A1`: all 19 measured operations at 1, 4, 8, 16, 18 and 28
coefficient digits, three datasets per size, once per timing scope
(`arithmetic_only` and `full_path`).

## Output

- Standard output: the Mare Mark JSONL of every experiment (validation,
  calibration, observation, summary records), each followed by one
  `"comparison"` record per `PerformanceResult`.
- `artifacts/dzmingli_vs_floating/common_digits.html`: a self-contained HTML report written with
  `mare_performance_report_html`. The directories are created when missing.

## Exit status

The executable aborts with `common-digits decimal differential validation failed` when any validation failed, after the
report has been written. A complete run without failures exits normally.

## Targets

`main.mbt` is compiled for `native` only. On `js`, `wasm`, `wasm-gc` and
`llvm` the package builds `main_unimplemented.mbt`, which prints that the
runner requires `native` and exits.

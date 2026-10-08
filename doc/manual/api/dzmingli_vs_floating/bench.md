# dzmingli_vs_floating/bench API

## Purpose

`Luna-Flow/diff_bench/dzmingli_vs_floating/bench` is an executable package. It has no public
items; its interface is the command line and the files it writes. It uses the
library package [`dzmingli_vs_floating`](../dzmingli_vs_floating.md).

## Importing

An executable package cannot be imported. Run it with `moon run` from the
repository root, as shown under [Command](#command); to reuse its pieces,
import the library package instead.

## Command

```sh
moon run --release src/dzmingli_vs_floating/bench --target native
```

The executable takes no arguments. The replay commands recorded in the JSONL
append operation, size and implementation arguments; the executable ignores
them and reruns the whole experiment.

## Experiments

It runs `run_mare_benchmark` six times with `default_benchmark_protocol()` and
seed `0xDEC1A1`, three datasets per size:

| Run | Operations | Coefficient digits | Scopes |
| --- | --- | --- | --- |
| scaling | add, subtract, multiply, divide, compare | 1, 4, 16, 64, 256, 1,024, 4,096, 8,192, 10,000 | `arithmetic_only`, `full_path` |
| stress | add, subtract, divide, compare | 16,384, 20,000 | `arithmetic_only`, `full_path` |
| extended | the 14 other exact operations | 1, 16, 64, 256, 1,024 | `arithmetic_only`, `full_path` |

## Output

- Standard output: the Mare Mark JSONL of every experiment (validation,
  calibration, observation, summary records), each followed by one
  `"comparison"` record per `PerformanceResult`.
- `artifacts/dzmingli_vs_floating/scaling.html`: a self-contained HTML report written with
  `mare_performance_report_html`. The directories are created when missing.

## Exit status

The executable aborts with `decimal differential validation failed` when any validation failed, after the
report has been written. A complete run without failures exits normally.

## Targets

`main.mbt` is compiled for `native` only. On `js`, `wasm`, `wasm-gc` and
`llvm` the package builds `main_unimplemented.mbt`, which prints that the
runner requires `native` and exits.

# dzmingli_vs_floating/bench tutorial

This page runs the `bench` executable of `dzmingli_vs_floating`, keeps its records, and checks
that the run is complete before you read its numbers.

| I want to | Use |
| --- | --- |
| reproduce the published `scaling` run | `moon run --release src/dzmingli_vs_floating/bench --target native` |
| record the host in the output | the `MARE_*` environment variables |
| know whether the run is usable | the `validation` and `summary` records of the JSONL |
| read the results | the `"comparison"` records and `artifacts/dzmingli_vs_floating/scaling.html` |

## Quick start

From the repository root:

```sh
moon run --release src/dzmingli_vs_floating/bench --target native \
  | sed -n '/^{/p' > artifacts/dzmingli_vs_floating/scaling.jsonl
```

The command compiles a release build for `native`, validates every dataset
against the oracle, measures both implementations and writes
`artifacts/dzmingli_vs_floating/scaling.html`. Open the HTML file in a browser.

## Everyday tasks

### Record the host

Mare Mark records only the facts you give it. Set them on the command line:

```sh
MARE_CPU="Apple M4" MARE_OS="macOS 26.5" MARE_BUILD_MODE=release \
  moon run --release src/dzmingli_vs_floating/bench --target native
```

Unset variables are recorded as `unknown` or `unspecified`.

### Check that the run is complete

Every Mare Mark summary record must contain `"complete":true`, and every
validation record must have `"status":"valid"` (for DzmingLi, failures from
4,096 digits are expected in the scaling run):

```sh
grep -c '"type":"validation"' artifacts/dzmingli_vs_floating/scaling.jsonl
grep '"type":"validation"' artifacts/dzmingli_vs_floating/scaling.jsonl | grep -vc '"status":"valid"'
```

### Read the comparison records

Each `"comparison"` line is one operation and size. The `*_median_us` fields
are median microseconds per operation, the speedup field is the GDA median over
the DzmingLi median, and `decision` applies the 3 % threshold.

## Going further

Render publication figures from the JSONL with the Python layouts in `tools/`,
as shown in the [package tutorial](../dzmingli_vs_floating.md). To change sizes or operations,
edit `main.mbt`; the library functions take the operation list and the
expanded size list as arguments.

## Common pitfalls

- Run with `--release` and `--target native`. Debug builds and other targets do
  not produce comparable numbers, and other targets do not run at all.
- Do not merge records from different targets or hosts into one report.
- A nonzero exit after a complete report means a validation failed; it is not a
  crash of the measurement.

## Next steps

- [API](../../api/dzmingli_vs_floating/bench.md) and [design](../../design/dzmingli_vs_floating/bench.md) of
  this executable.
- [Performance analysis](../../performance/dzmingli_vs_floating.md) of the published run.

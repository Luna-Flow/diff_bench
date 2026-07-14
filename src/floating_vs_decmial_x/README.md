# floating_vs_decmial_x

This package is the isolated benchmark for `moonbitlang/x/decimal` versus
`Luna-Flow/floating/decimal_gda`.

- `DecimalValue` stores an integer coefficient and decimal scale.
- `normalize` and `canonical_string` provide one comparison boundary for all implementations.
- `prepare_fixture` materializes both X Decimal and GDA Decimal values outside the timed path.
- `run_x` and `run_gda` are the two benchmark execution adapters.
- `oracle_multiply` and `oracle_divide` model a 28-digit, truncating decimal policy.
- `generate_cases` is deterministic by construction; it does not use wall-clock time or process-global random state.

Mare Mark 0.2.0 supplies stable input fingerprinting, continuous seeded balanced execution order,
median-based repeated-observation reporting, synchronization hooks, and complete environment
metadata. Adapters consume the same neutral fixture and
compare their output through `canonical_observation`. The native run uses three independently
seeded datasets for each 1, 4, 16, 64, 256, 1024, and 4096 digit point, with 20 paired confirmatory
samples per dataset (60 paired samples per reported point).

Results are reported in two semantic groups:

- `exact_overlap` covers operations whose mathematical result is represented exactly by both APIs.
- `x_compatible` covers multiplication and division with X's 28-fractional-digit, toward-zero
  result policy; GDA performs the matching post-operation quantization inside the timed path.

Every comparison record includes a timing scope. `arithmetic_only` contains one public operation
per implementation. `semantic_equivalent_pipeline` measures the complete public API cost required
to reproduce X's result policy and is never aggregated with arithmetic-only results. GDA division
uses the minimum precision required by the selected semantic contract rather than an operand-size
sum unrelated to the requested output precision.

This is a fair public-API comparison: conversion, fixture construction, validation, and output
canonicalization are excluded; each implementation receives the identical prepared operand pair;
execution order is continuously balanced across phases; and paired statistics explicitly match
dataset, repetition, and block identifiers. It is not a claim of universal fairness: the benchmark does not
measure allocation or memory use, does not replace the shared BigInt oracle with an independent
third implementation, and native measurements must be reproduced on the target hardware and
toolchain.

Run the native performance differential with:

```sh
moon run --release src/floating_vs_decmial_x/bench --target native
```

For the X-oriented common coefficient sizes of 1, 4, 8, 16, 18, and 28
digits, run the independent common-digit line with:

```sh
moon run --release src/floating_vs_decmial_x/bench_common --target native
```

It uses the same validation and measurement protocol and writes
`artifacts/mare_mark_common_digits_performance.html`, leaving the wide scaling
report untouched.

Set `MARE_CPU`, `MARE_OS`, `MARE_BUILD_MODE`, and related `MARE_*` variables
when host facts are known. Missing host facts are recorded as `unknown` or
`unspecified`, so results never inherit machine details from source code.

The command emits Mare Mark validation, calibration, raw observation, summary, and paired
comparison records as JSONL. Timings are reported per operation and coefficient digit size;
different targets must be run and analyzed separately.

After a native run, the Mare Plot IR backend also writes
`artifacts/mare_mark_performance.html`. It contains one scaling plot per operation and timing
scope, plus X-versus-GDA speedup plots. The existing `scripts/plot_benchmark.py` SVG path remains
available for comparison and regression checks.

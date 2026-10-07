# Running and reproducing

## Run the benchmark

From the repository root, run:

```sh
moon run --release src/floating_vs_decmial_x/bench --target native
```

To compare only the coefficient sizes common in X, 1, 4, 8, 16, 18 and 28 digits, run:

```sh
moon run --release src/floating_vs_decmial_x/bench_common --target native
```

## Record the environment

Pass known host facts through `MARE_CPU`, `MARE_OS`, `MARE_BUILD_MODE` and the other `MARE_*` environment variables. Facts that are not provided are recorded as `unknown` or `unspecified`; they are never inferred from the source code or from another machine.

## Read the results

- `arithmetic_only`: each implementation executes exactly one public arithmetic operation.
- `semantic_equivalent_pipeline`: includes the complete public API flow needed to reproduce X's result policy.
- [scaling.html](../../../artifacts/floating_vs_decmial_x/scaling.html): the report over the wide range of coefficient sizes.
- [common_digits.html](../../../artifacts/floating_vs_decmial_x/common_digits.html): the report for common digit counts.

Results from different MoonBit targets must be run and analyzed separately; they cannot be merged.

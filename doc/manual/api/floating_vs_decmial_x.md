# `floating_vs_decmial_x` API

## Positioning

This package is the repository's differential-testing and performance benchmark, not a production runtime library. It is kept only in the GitHub repository for reference, reproduction and regression checks, and is not published to Mooncakes.

## Entry points

```sh
moon run --release src/floating_vs_decmial_x/bench --target native
moon run --release src/floating_vs_decmial_x/bench_common --target native
```

`bench` measures coefficients of 1, 4, 16, 64, 256, 1024 and 4096 digits; `bench_common` measures coefficients of 1, 4, 8, 16, 18 and 28 digits.

## Main exports

- `DecimalValue`: a neutral representation as a coefficient and a decimal scale.
- `DecimalSemantics`: the `ExactOverlap` and `XCompatible` semantic groups.
- `Operation`: addition, subtraction, multiplication, division, comparison and the other measured operations.
- `prepare_fixture`: builds the shared fixture for both implementations outside the timed region.
- `working_precision`: computes the working precision GDA needs for an operation and a semantic group.
- `canonical_observation`: converts the results of both implementations to one comparison boundary.

The benchmark output consists of validation, calibration, raw observation, summary and paired comparison JSONL records, together with HTML reports under `artifacts/`.

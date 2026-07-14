# DzmingLi decimal versus floating GDA

This package uses Mare Mark to compare:

- `DzmingLi/decimal@0.2.2`
- `Luna-Flow/floating/decimal_gda@0.6.1`

The benchmark intentionally pins `DzmingLi/decimal@0.2.2` for historical
comparison even though that package is deprecated and has moved to
`moonbit-community/decimal`.

## Comparison contract

Both implementations receive values generated from the same neutral
coefficient-and-scale model. Every measured dataset is first validated against
the independent `BigInt` oracle. Addition, subtraction, multiplication, and
comparison are exact. Division uses only terminating divisors (`2`, `8`, and
`25`) so that both libraries and the oracle can represent the exact
finite result without a compatibility quantization policy.

The benchmark runs the same corpus under two timing scopes:

- `arithmetic_only`: decimal operands and contexts are prepared before timing;
  the public arithmetic operation is measured.
- `full_path`: both decimal operands are parsed and constructed inside each
  timed invocation under equivalent precision and rounding contexts, followed
  by the same public arithmetic operation. Input serialization, context setup,
  fixture setup, validation, calibration, and reporting remain outside timing.

There is no X-decimal compatibility mode and no fixed 28-digit quantization in
this comparison.

The scalable exact-finite performance surface contains add, subtract,
multiply, divide, divide-integer, remainder, integer power, FMA, square root of
perfect squares, unary plus/minus/abs, quantize, rescale, scaleb, reduce,
to-integral-exact, to-integral-value, and compare. Transcendental `exp`, `ln`,
and `log10` are covered by official decTest correctness but are not assigned a
coefficient-size scaling benchmark: identity-only fixtures would not measure
their algorithms, while general results require a different independent
high-precision oracle.

## GDA conformance audit

Run the pinned official GDA `decTest` audit for the operation families used by
this benchmark:

```sh
sh tools/run_dzmingli_dectest_audit.sh
```

The audit verifies the official archive SHA-256 before use. It executes the
complete `add`, `subtract`, `multiply`, `divide`, `compare`, and `base` files
plus the remaining shared GDA arithmetic files against floating GDA, including
expected representations and conditions. It
then runs every row for this benchmark's implemented operation families from
the same files through the DzmingLi runner. Before doing so, it verifies that
the runner commit's library sources are byte-for-byte identical to the
installed `DzmingLi/decimal@0.2.2` sources.

This conformance audit complements rather than replaces the large-coefficient
benchmark oracle: official `decTest` concentrates on semantic boundary cases,
while this benchmark deliberately extends coefficient sizes into thousands of
digits.

## Running

Run the scaling benchmark. Every coefficient size uses the same three operand
profiles and 60 paired confirmatory samples. All operations continue through
8,192 and 10,000 digits; addition, subtraction, division, and comparison also
run at 16,384 and 20,000 digits. The operation-specific ceiling avoids a known
`DzmingLi/decimal@0.2.2` digit-count overflow beyond its comparable range:

```sh
moon run --release src/dzmingli_vs_floating/bench --target native
```

Run the common-digit benchmark for 1, 4, 8, 16, 18, and 28-digit coefficients:

```sh
moon run --release src/dzmingli_vs_floating/bench_common --target native
```

The runners emit Mare Mark validation, calibration, observation, summary, and
comparison JSONL. They also write self-contained Plot IR reports to:

- `artifacts/mare_mark_dzmingli_vs_floating_performance.html`
- `artifacts/mare_mark_dzmingli_vs_floating_common_digits.html`
- `artifacts/mare_mark_dzmingli_vs_floating_extended.jsonl`
- `artifacts/mare_mark_dzmingli_vs_floating_common_digits.jsonl`

Each report plots median latency for both implementations and DzmingLi speedup
versus floating GDA, separately for `arithmetic_only` and `full_path`.

## Fairness controls

- Both implementations receive identical canonical input strings, confirmed by
  matching fingerprints across both timing scopes.
- Both use the same computed working precision, Down rounding, effectively
  unbounded exponent range, and no clamp.
- Compare times only each library's public compare operation; result conversion
  and canonical validation happen outside timing.
- Mare Mark uses per-implementation calibration, five warmups, BalancedBlocks
  execution order, 20 confirmatory repetitions, and explicit
  dataset/repetition/block pairing.
- Each digit size uses the same three scale profiles (`0`, `8`, and `28`) and
  therefore has 60 paired samples whenever both implementations are correct.

The run is fair for the stated exact-finite API contract. It is not evidence
for repeating division, arbitrary large denominators, other hardware, or
frequency-controlled execution; those limitations are recorded in the results.

## Observed DzmingLi non-compliance

The fairness-audited native run found 108 DzmingLi correctness failures
beginning at 4,096 coefficient digits, while floating GDA passed every oracle
validation.
DzmingLi also aborts at larger stress sizes because its decimal digit estimator
overflows an `Int` intermediate. Invalid scales are excluded from paired
speedup calculations rather than being reported as meaningful performance
comparisons.

On the current native target, `digit_count` computes `bit_length * 30103` in a
signed `Int`. That intermediate can overflow once a coefficient reaches about
21,475 decimal digits. Operations that nearly double coefficient length, such
as multiply, FMA products, square, or integer `power(..., 2)`, can therefore
cross the boundary from inputs around 10,738 digits. These are analytical
thresholds, not guarantees for every operand: the completed run proves 10,000
digits for multiplication and 20,000 for non-multiplication operations, while
32,768- and 65,536-digit stress attempts reproduced the abort.

See [`BENCHMARK_RESULTS.md`](BENCHMARK_RESULTS.md) for the exact validation
counts, affected operations, abort signature, environment, and reporting policy.

# Extended benchmark findings

This document records the correctness boundary discovered while running the
extended native benchmark on 2026-07-15.

## Environment

- CPU: Apple M4
- OS: macOS 26.5
- MoonBit: `moon 0.1.20260703 (6fbf8c3 2026-07-03)`
- Build: release/native
- DzmingLi implementation: `DzmingLi/decimal@0.2.2`
- GDA implementation: `Luna-Flow/floating/decimal_gda@0.7.1`

## Correctness results

The deterministic corpus produced 1,476 oracle validations across both timing
scopes. `floating_decimal_gda` passed all 738 of its validations. DzmingLi
passed 630 of 738 and failed 108. The common-digits run adds 1,368 validations
and all pass.

The official GDA `decTest` audit additionally executes 23 arithmetic and base
files covering abs, add/subtract, multiply/divide/divide-integer, remainder,
power, FMA, square root, exp/ln/log10, quantize/rescale/scaleb, reduce,
to-integral, unary plus/minus, compare, apply, and formatting. Floating GDA
passes all 17,651 legal executable rows; 32 `#` diagnostic rows are excluded by
the official runner. DzmingLi passes every arithmetic, comparison, and `apply`
rows but fails 329 `toSci` rows because formatting does not apply the active
precision and rounding context. This means the benchmark's current `Format`
identity path is not a GDA formatting conformance test.

Those six files total 358,641 bytes. Their largest finite input coefficient is
64 digits and largest finite expected coefficient is 56 digits, although
exponent-boundary cases reach magnitude 99,999,999,999. They therefore provide
strong GDA semantic coverage but do not reproduce the 4,096–20,000-digit
coefficient scale below; the independent exact-finite `BigInt` stress oracle
remains necessary for that dimension.

| Implementation | Passed | Failed | Total |
| --- | ---: | ---: | ---: |
| `floating_decimal_gda` | 738 | 0 | 738 |
| `dzmingli_decimal` | 630 | 108 | 738 |

The DzmingLi failures are numerical mismatches against the independent exact
`BigInt` oracle. They begin at 4,096 coefficient digits and affect addition,
subtraction, multiplication, and exact terminating division under both
`arithmetic_only` and `full_path`. Comparison remains correct through the
20,000-digit stress input covered by the completed run.

This is not a rounding-policy difference. The benchmark uses no X-compatible
mode or 28-digit quantization, and division inputs are restricted to exact
terminating divisors.

## Larger-input abort

An initial stress attempt that included 32,768 and 65,536 coefficient digits
could not complete because `DzmingLi/decimal@0.2.2` aborted with:

```text
pow10: negative exponent -10274
```

The failure comes from DzmingLi's decimal digit estimator multiplying
`bit_length * 30103` in `Int`. That intermediate overflows at sufficiently
large coefficients and produces a negative power-of-ten exponent. Multiplication
can reach this boundary earlier because its result may contain nearly twice as
many digits as either operand.

The completed comparison therefore runs every operation through 10,000 digits
and runs addition, subtraction, exact terminating division, and comparison
through 20,000 digits. The abort is retained here as a correctness and
robustness finding rather than silently lowering the intended stress coverage.

For the current native signed `Int`, the multiplication first risks overflow
above 71,337 coefficient bits, approximately 21,475 decimal digits. A direct
add/subtract/divide operand therefore crosses the analytical boundary near
21.5K digits. Multiply, an FMA product, a square, or integer power with exponent
2 can produce roughly twice the input digits and may cross it from inputs near
10,738 digits. This explains why 10,000-digit multiplication completes while
larger multiplication was excluded, and why 20,000-digit non-multiplication
cases complete but 32,768 digits abort. The exact first failing input depends on
the result coefficient and operation path; these values are bounds, not a claim
that every operand fails at one exact digit count.

## Reporting policy

Latency and speedup are paired only where both implementations pass the oracle.
At a scale where DzmingLi is incorrect, the operation latency plot retains the
validated GDA measurement but omits the DzmingLi point, and the speedup plot
omits that scale entirely. JSONL comparison records mark these entries with
`"correctness_valid": false` and `"decision": "invalid_correctness"`.

## Fairness audit

The final run includes the following controls:

- The two timing scopes use identical generated values and identical canonical
  input strings. All 318 implementation/dataset fingerprint groups were paired
  across scopes with zero fingerprint mismatches.
- Every coefficient size uses the same three operand profiles. The profiles
  cover decimal scales `0`, `8`, and `28`; terminating division uses divisors
  `2`, `8`, and `25`.
- Both adapters parse and operate with the same computed working precision,
  Down rounding, effectively unbounded exponent ranges, and no clamp.
- `arithmetic_only` excludes operand parsing and context construction.
  `full_path` includes context-aware parsing of both already-serialized input
  strings plus arithmetic, but excludes neutral-value serialization and context
  construction.
- Both compare adapters time only the public compare operation. Conversion to
  the neutral oracle representation occurs outside the measured batch.
- Both implementations are linked into the same release/native binary and run
  in the same process and Moon GC runtime.
- Mare Mark performs five warmups, targets 5 ms calibrated batches per
  implementation, alternates implementation order with BalancedBlocks, records
  20 confirmatory repetitions per dataset, and reports outliers without
  trimming them.
- All 70 correctness-valid comparison points contain exactly 60 explicitly
  matched dataset/repetition/block sample pairs. Invalid scales do not produce
  speedup decisions.

Remaining limits are relevant when interpreting the results:

- CPU frequency was uncontrolled, although balanced ordering limits temporal
  bias between implementations.
- The corpus has three deterministic profiles rather than a random operand
  distribution.
- Division covers exact terminating small divisors, not repeating quotients or
  large-denominator division.
- Timing scopes are reported separately; their absolute values are not a
  paired estimate of parsing overhead.
- Results describe one Apple M4 host and should not be generalized to other
  architectures without rerunning the benchmark.

The generated artifacts are:

- `artifacts/dzmingli_vs_floating/scaling.html`
- `artifacts/dzmingli_vs_floating/scaling.jsonl`
- `artifacts/dzmingli_vs_floating/common_digits.html`
- `artifacts/dzmingli_vs_floating/common_digits.jsonl`
- `artifacts/dzmingli_vs_floating/main.{png,pdf,svg}`
- `artifacts/dzmingli_vs_floating/main.ir.json`
- `artifacts/dzmingli_vs_floating/supplementary.{png,pdf,svg}`
- `artifacts/dzmingli_vs_floating/supplementary.ir.json`

These artifacts use the migrated `mare_mark@0.3.0` pipeline. The versioned
JSONL is parsed into retained `mmks_1` Plot IR, then the unified Matplotlib
layouts render PNG for previews, PDF for distribution and archival, and SVG
for editable publication use without recalculating benchmark results.

## Performance highlights

For small 1- and 16-digit inputs, DzmingLi is faster in both timing scopes.
Around 256 digits, floating GDA becomes faster for the tested arithmetic
operations; the full report contains every measured scale and paired decision.

At 1,024 digits, where both implementations still pass the oracle, the median
latencies are:

| Operation | Scope | DzmingLi µs/op | floating GDA µs/op | GDA speedup |
| --- | --- | ---: | ---: | ---: |
| add | arithmetic only | 29.261 | 0.978 | 29.92× |
| subtract | arithmetic only | 29.260 | 0.970 | 30.17× |
| multiply | arithmetic only | 59.400 | 16.798 | 3.54× |
| divide | arithmetic only | 78.978 | 3.675 | 21.49× |
| compare | arithmetic only | 12.459 | 0.131 | 95.44× |
| add | full path | 174.869 | 8.331 | 21.00× |
| subtract | full path | 174.518 | 8.346 | 20.91× |
| multiply | full path | 205.549 | 24.133 | 8.52× |
| divide | full path | 152.145 | 7.427 | 20.49× |
| compare | full path | 156.066 | 7.475 | 20.88× |

DzmingLi is invalid at the larger arithmetic scales, so the extreme points are
reported as validated GDA latency rather than as speedups:

| Digits | Operation | GDA arithmetic-only µs/op | GDA full-path µs/op |
| ---: | --- | ---: | ---: |
| 10,000 | add | 7.518 | 77.640 |
| 10,000 | subtract | 7.530 | 77.817 |
| 10,000 | multiply | 748.170 | 823.110 |
| 10,000 | divide | 30.021 | 65.515 |
| 20,000 | add | 14.810 | 154.468 |
| 20,000 | subtract | 15.083 | 155.582 |
| 20,000 | divide | 60.588 | 131.363 |
| 20,000 | compare | 0.130 | 139.865 |

These figures are from one controlled local run and should be interpreted with
the environment metadata above. Correctness results are deterministic for the
recorded seed; latency should be remeasured on the target deployment host.

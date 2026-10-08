# floating_vs_decmial_x API

## Purpose

The package `Luna-Flow/diff_bench/floating_vs_decmial_x` compares
`moonbitlang/x/decimal` (X) with `Luna-Flow/floating/decimal_gda@0.7.1` (GDA)
on identical decimal inputs, checks both against a `BigInt` oracle, and
measures them with Mare Mark. It is a benchmark harness kept in the GitHub
repository for reproduction; it is not a runtime dependency for other
projects. Functions abort on input outside their contract.

The package name keeps the historical spelling `decmial`. The
[tutorial](../tutorial/floating_vs_decmial_x.md) shows the items in use, and
the [design page](../design/floating_vs_decmial_x.md) derives the precision
contracts. Source: `src/floating_vs_decmial_x/`.

## Importing

Inside the module, add the package to a `moon.pkg`, with `bigint` when you
build `DecimalValue` literals:

```moonbit nocheck
import {
  "Luna-Flow/diff_bench/floating_vs_decmial_x",
  "moonbitlang/core/bigint",
}
```

The examples on this page are blackbox tests that call the package as
`@floating_vs_decmial_x`. The asynchronous examples also need
`"moonbitlang/async"` in the test imports.

## Neutral decimal model

These items have the same definitions as in
[`dzmingli_vs_floating`](dzmingli_vs_floating.md#neutral-decimal-model); the
two packages keep separate copies so that each benchmark builds alone.

### `DecimalValue`

`DecimalValue` is the implementation-neutral decimal $(c, s)$ with value
$c \cdot 10^{-s}$.

```mbti
pub(all) struct DecimalValue {
  coefficient : @bigint.BigInt
  scale : Int
}
```

### `normalize`

`normalize` removes trailing zeros from the coefficient while the scale stays
non-negative; zero becomes $(0, 0)$.

```mbti
pub fn normalize(DecimalValue) -> DecimalValue
```

### `canonical_string`

`canonical_string` renders the normalized value in positional notation
without an exponent; equal numbers give equal strings.

```mbti
pub fn canonical_string(DecimalValue) -> String
```

### `parse_decimal_value`

`parse_decimal_value` reads a finite decimal string, with optional sign,
point and exponent, into a normalized value. It aborts on anything else.

```mbti
pub fn parse_decimal_value(String) -> DecimalValue
```

### `OracleResult`

`OracleResult` holds a normalized value and its canonical string.

```mbti
pub struct OracleResult {
  value : DecimalValue
  canonical : String
}
```

### `to_oracle_result`

`to_oracle_result` normalizes a value and pairs it with its canonical string.

```mbti
pub fn to_oracle_result(DecimalValue) -> OracleResult
```

```moonbit
test "neutral decimal model" {
  let v = @floating_vs_decmial_x.parse_decimal_value("0.00120")
  inspect(v.coefficient, content="12")
  inspect(v.scale, content="4")
  inspect(@floating_vs_decmial_x.canonical_string(v), content="0.0012")
  let r = @floating_vs_decmial_x.to_oracle_result({ coefficient: -1200N, scale: 2 })
  inspect(r.canonical, content="-12")
}
```

## Exact arithmetic

### `add`

`add` returns the exact sum after aligning both operands to the larger scale.

```mbti
pub fn add(DecimalValue, DecimalValue) -> DecimalValue
```

### `subtract`

`subtract` returns the exact difference after the same alignment.

```mbti
pub fn subtract(DecimalValue, DecimalValue) -> DecimalValue
```

### `multiply`

`multiply` returns the exact product.

```mbti
pub fn multiply(DecimalValue, DecimalValue) -> DecimalValue
```

### `compare`

`compare` returns `-1`, `0` or `1`.

```mbti
pub fn compare(DecimalValue, DecimalValue) -> Int
```

```moonbit
test "exact arithmetic" {
  let a = @floating_vs_decmial_x.parse_decimal_value("123.45")
  let b = @floating_vs_decmial_x.parse_decimal_value("-4.5")
  let show = @floating_vs_decmial_x.canonical_string
  inspect(show(@floating_vs_decmial_x.add(a, b)), content="118.95")
  inspect(show(@floating_vs_decmial_x.subtract(a, b)), content="127.95")
  inspect(show(@floating_vs_decmial_x.multiply(a, b)), content="-555.525")
  inspect(@floating_vs_decmial_x.compare(b, a), content="-1")
}
```

## Reference oracle

The oracle models X's result policy: at most 28 fractional digits, extra
digits truncated toward zero.

### `oracle_multiply`

`oracle_multiply` returns the exact product, truncated toward zero to 28
fractional digits when its scale exceeds 28.

```mbti
pub fn oracle_multiply(DecimalValue, DecimalValue) -> DecimalValue
```

### `oracle_divide`

`oracle_divide` returns the quotient truncated toward zero to 28 fractional
digits, computed with integer division only.

```mbti
pub fn oracle_divide(DecimalValue, DecimalValue) -> DecimalValue
```

With $k = 28 + s_r - s_\ell$ the result coefficient is
$\operatorname{trunc}(c_\ell \cdot 10^{k} / c_r)$ when $k \ge 0$ and
$\operatorname{trunc}(\operatorname{trunc}(c_\ell / 10^{-k}) / c_r)$
otherwise, at scale 28. Aborts on a zero divisor. Repeating quotients are
fine here, unlike in `dzmingli_vs_floating`.

### `oracle_operation`

`oracle_operation` evaluates an `Operation` with the rules above: exact
`Add`, `Subtract` and `Compare`, the truncating `Multiply` and `Divide`, and
the identity for `Parse` and `Format`.

```mbti
pub fn oracle_operation(Operation, DecimalValue, DecimalValue) -> OracleResult
```

The oracle does not depend on `DecimalSemantics`; the
[design page](../design/floating_vs_decmial_x.md#one-oracle-for-both-groups)
shows why one oracle serves both groups.

```moonbit
test "reference oracle" {
  let one = @floating_vs_decmial_x.parse_decimal_value("1")
  let three = @floating_vs_decmial_x.parse_decimal_value("3")
  inspect(
    @floating_vs_decmial_x.oracle_operation(Divide, one, three).canonical,
    content="0.3333333333333333333333333333",
  )
  let tiny : @floating_vs_decmial_x.DecimalValue = { coefficient: 1N, scale: 20 }
  let wide : @floating_vs_decmial_x.DecimalValue = { coefficient: 123456789N, scale: 10 }
  inspect(
    @floating_vs_decmial_x.canonical_string(@floating_vs_decmial_x.oracle_multiply(tiny, wide)),
    content="0.0000000000000000000001234567",
  )
}
```

## Operations, semantics and suites

### `Operation`

`Operation` lists the operation families of this benchmark.

```mbti
pub(all) enum Operation {
  Add
  Subtract
  Multiply
  Divide
  Compare
  Parse
  Format
}
```

`Parse` and `Format` return the prepared left operand on both sides and are
not run by the executables.

### `operation_name`

`operation_name` returns the snake-case name used in records, such as
`"divide"`.

```mbti
pub fn operation_name(Operation) -> String
```

### `DecimalSemantics`

`DecimalSemantics` selects the semantic contract both implementations must
meet.

```mbti
pub(all) enum DecimalSemantics {
  ExactOverlap
  XCompatible
}
```

`ExactOverlap` uses inputs whose exact result both libraries represent, so no
rounding happens on either side. `XCompatible` reproduces X's
28-fractional-digit truncation in GDA by a `quantize` after `multiply` and
`divide`, inside the timed path.

### `decimal_semantics_name`

`decimal_semantics_name` returns `"exact_overlap"` or `"x_compatible"`.

```mbti
pub fn decimal_semantics_name(DecimalSemantics) -> String
```

### `OperandShape`

`OperandShape` labels a generated case; the label does not influence the
operands.

```mbti
pub(all) enum OperandShape {
  Small
  Large
  Boundary
  Cancellation
  Repeating
}
```

### `TimingScope`

`TimingScope` names what a timed invocation contains, for suite metadata.

```mbti
pub(all) enum TimingScope {
  ConstructionAndOperation
  OperationOnly
}
```

The Mare Mark runner does not read it. Comparison records carry a string scope
instead: `"semantic_equivalent_pipeline"` for `Multiply` and `Divide` under
`XCompatible`, `"arithmetic_only"` otherwise.

### `Suite`

`Suite` is descriptive metadata for a benchmark suite.

```mbti
pub struct Suite {
  name : String
  operations : Array[Operation]
  scales : Array[Int]
  timing_scope : TimingScope
  warmup : Int
  samples : Int
}
```

### `default_suite`

`default_suite` returns the suite `"decimal-x-floating-gda"` with all seven
operations, scales `[0, 2, 6, 18, 28]`, `OperationOnly`, 5 warmups and 20
samples.

```mbti
pub fn default_suite() -> Suite
```

### `suite_case_count`

`suite_case_count` returns operations × scales × cases per operation.

```mbti
pub fn suite_case_count(Suite, Int) -> Int
```

```moonbit
test "operations, semantics and suites" {
  inspect(@floating_vs_decmial_x.operation_name(Divide), content="divide")
  inspect(@floating_vs_decmial_x.decimal_semantics_name(XCompatible), content="x_compatible")
  let suite = @floating_vs_decmial_x.default_suite()
  inspect(@floating_vs_decmial_x.suite_case_count(suite, 2), content="70")
}
```

## Deterministic cases

### `generate_decimal`

`generate_decimal(seed, digits, scale, negative)` builds a decimal string with
exactly `digits` coefficient digits in $1..9$, `scale` of them fractional.
Aborts if `digits <= 0` or `scale < 0`.

```mbti
pub fn generate_decimal(Int, Int, Int, Bool) -> String
```

### `BenchmarkCase`

`BenchmarkCase` is a generated case; its strings are the serialization
boundary.

```mbti
pub struct BenchmarkCase {
  id : String
  operation : Operation
  shape : OperandShape
  left : String
  right : String
  scale : Int
}
```

### `generate_cases`

`generate_cases(seed, count, operation)` returns `count` reproducible cases
with $1..24$ digits and scales $0..8$, without clock or global random state.

```mbti
pub fn generate_cases(Int, Int, Operation) -> Array[BenchmarkCase]
```

### `serialize_case`

`serialize_case` joins `decimal-neutral-v1` and the case fields with newlines.

```mbti
pub fn serialize_case(BenchmarkCase) -> String
```

### `fingerprint_case`

`fingerprint_case` hashes `serialize_case` with Mare Mark's
`stable_fingerprint`.

```mbti
pub fn fingerprint_case(BenchmarkCase) -> String
```

### `expand_digit_scales`

`expand_digit_scales(sizes, n)` repeats each coefficient size `n` times, one
Mare Mark dataset per repetition.

```mbti
pub fn expand_digit_scales(Array[Int], Int) -> Array[Int]
```

```moonbit
test "deterministic cases" {
  inspect(@floating_vs_decmial_x.generate_decimal(0, 2, 4, true), content="-0.0018")
  let first = @floating_vs_decmial_x.generate_cases(17, 4, Multiply)
  let again = @floating_vs_decmial_x.generate_cases(17, 4, Multiply)
  inspect(first[3].right == again[3].right, content="true")
  assert_eq(@floating_vs_decmial_x.expand_digit_scales([1, 4], 3), [1, 1, 1, 4, 4, 4])
}
```

## Fixtures and adapters

### `working_precision`

`working_precision(operation, left, right, semantics?)` returns the GDA
context precision of a fixture. `semantics` defaults to `XCompatible`.

```mbti
pub fn working_precision(Operation, DecimalValue, DecimalValue, semantics? : DecimalSemantics) -> Int
```

With $d_\ell, d_r$ the coefficient digit counts and $s_\ell, s_r$ the scales:

| Operation | Precision |
| --- | --- |
| `Add`, `Subtract` | $\max(d_\ell, d_r) + \lvert s_\ell - s_r \rvert + 2$ |
| `Multiply` | $d_\ell + d_r + 1$ |
| `Divide`, `ExactOverlap` | $d_\ell + d_r + 2$ |
| `Divide`, `XCompatible` | $\max(1,\ d_\ell - s_\ell - d_r + s_r + 1) + 30$ |
| `Compare`, `Parse`, `Format` | $\max(d_\ell, d_r) + 1$ |

The [design page](../design/floating_vs_decmial_x.md#precision-contracts)
derives each line and the operand classes it covers.

### `DecimalFixture`

`DecimalFixture` holds both implementations' operands, built before timing.

```mbti
pub struct DecimalFixture {
  neutral_left : DecimalValue
  neutral_right : DecimalValue
  operation : Operation
  semantics : DecimalSemantics
  x_left : @decimal.Decimal
  x_right : @decimal.Decimal
  gda_left : @decimal_gda.Decimal
  gda_right : @decimal_gda.Decimal
  gda_quantum_28 : @decimal_gda.Decimal
  gda_context : @decimal_gda.GdaContext
}
```

`@decimal` is `moonbitlang/x/decimal`. `gda_quantum_28` is $10^{-28}$, the
quantum of the `XCompatible` post-processing.

### `prepare_fixture`

`prepare_fixture(operation, left, right, semantics?)` computes the precision
$p$, converts both operands for X and for GDA, and builds a GDA context with
precision $p$ and rounding toward zero.

```mbti
pub fn prepare_fixture(Operation, DecimalValue, DecimalValue, semantics? : DecimalSemantics) -> DecimalFixture
```

`semantics` defaults to `XCompatible`. The GDA operands are parsed with
precision $p$ and half-even rounding, so an operand with more than $p$
significant digits is rounded; see the
[known limitation](../design/floating_vs_decmial_x.md#known-limitation-operand-rounding-in-x-compatible-division).

### `x_from_neutral`

`x_from_neutral` converts a value with `Decimal::new`; it aborts when the
scale is outside X's range $0..28$.

```mbti
pub fn x_from_neutral(DecimalValue) -> @decimal.Decimal
```

### `gda_from_neutral`

`gda_from_neutral(value, precision)` parses the canonical string with
`Decimal::from_string(precision~)`.

```mbti
pub fn gda_from_neutral(DecimalValue, Int) -> @decimal_gda.Decimal
```

### `DecimalObservation`

`DecimalObservation` is the raw result of one adapter call.

```mbti
pub(all) enum DecimalObservation {
  X(@decimal.Decimal)
  XCompare(Int)
  Gda(@decimal_gda.GdaOutcome[@decimal_gda.Decimal])
}
```

`XCompare` holds X's comparison result already reduced to `-1`, `0` or `1`.

### `run_x`

`run_x` performs the fixture's operation with X's operators `+`, `-`, `*`,
`/` or `Compare::compare`.

```mbti
pub fn run_x(DecimalFixture) -> DecimalObservation
```

### `run_gda`

`run_gda` performs the fixture's operation with floating GDA; under
`XCompatible` it also quantizes products whose scale exceeds 28 and every
quotient to $10^{-28}$.

```mbti
pub fn run_gda(DecimalFixture) -> DecimalObservation
```

### `canonical_x`

`canonical_x` converts an X decimal to a normalized `DecimalValue` from its
coefficient and scale.

```mbti
pub fn canonical_x(@decimal.Decimal) -> DecimalValue
```

### `canonical_observation`

`canonical_observation` converts any observation to a normalized
`DecimalValue`; GDA results go through `to_string` and `parse_decimal_value`.

```mbti
pub fn canonical_observation(DecimalObservation) -> DecimalValue
```

```moonbit
test "fixtures and adapters" {
  let one = @floating_vs_decmial_x.parse_decimal_value("1")
  let three = @floating_vs_decmial_x.parse_decimal_value("3")
  inspect(@floating_vs_decmial_x.working_precision(Divide, one, three), content="31")
  let fixture = @floating_vs_decmial_x.prepare_fixture(Divide, one, three)
  let show = (o : @floating_vs_decmial_x.DecimalObservation) => {
    @floating_vs_decmial_x.canonical_string(
      @floating_vs_decmial_x.canonical_observation(o),
    )
  }
  inspect(show(@floating_vs_decmial_x.run_x(fixture)), content="0.3333333333333333333333333333")
  inspect(show(@floating_vs_decmial_x.run_gda(fixture)), content="0.3333333333333333333333333333")
}
```

## Mare Mark integration

### `MareDecimalInput`

`MareDecimalInput` is the materialized input of one Mare Mark dataset.

```mbti
pub(all) struct MareDecimalInput {
  left : DecimalValue
  right : DecimalValue
  operation : Operation
  semantics : DecimalSemantics
  digits : Int
  left_scale : Int
  right_scale : Int
}
```

### `PerformanceResult`

`PerformanceResult` summarizes one operation, semantic group and coefficient
size from paired confirmatory samples.

```mbti
pub(all) struct PerformanceResult {
  operation : Operation
  semantics : DecimalSemantics
  timing_scope : String
  digits : Int
  x_median_us : Double
  gda_median_us : Double
  gda_relative_delta_pct : Double
  x_speedup_vs_gda : Double
  decision : String
  samples : Int
}
```

`x_speedup_vs_gda` is the GDA median divided by the X median (above $1$ means
X is faster). `decision` is `"gda_faster"`, `"x_faster"`, `"equivalent"`,
`"invalid"` or `"unknown"`. Unlike `dzmingli_vs_floating`, results are always
paired; a validation failure shows up only in the report counts.

### `PerformanceResult::to_json`

`PerformanceResult::to_json` renders a `"comparison"` JSONL record with
artifact version `mmka_1`.

```mbti
pub fn PerformanceResult::to_json(Self) -> String
```

### `MareBenchmarkReport`

`MareBenchmarkReport` collects the results, raw JSONL and validation counts of
a run; `validation_count` counts passed and failed validations.

```mbti
pub(all) struct MareBenchmarkReport {
  results : Array[PerformanceResult]
  jsonl : String
  validation_count : Int
  failed_count : Int
}
```

### `smoke_protocol`

`smoke_protocol` returns the short test protocol: 2 warmups, 0.5 ms
calibration batches and 3 confirmatory repetitions.

```mbti
pub fn smoke_protocol() -> @model.RunProtocol
```

### `default_benchmark_protocol`

`default_benchmark_protocol` returns the protocol of the published runs: 5
warmups, 5 ms calibration batches, balanced blocks with seed `0xDEC1A1`,
outliers reported only, and 20 confirmatory repetitions.

```mbti
pub fn default_benchmark_protocol() -> @model.RunProtocol
```

### `benchmark_environment`

`benchmark_environment` builds the environment snapshot from the `MARE_*`
environment variables, with fixed defaults for missing ones.

```mbti
pub fn benchmark_environment() -> @model.EnvironmentSnapshot
```

### `run_mare_benchmark`

`run_mare_benchmark(operations, semantics, digit_scales, protocol, seed)` runs
one Mare Mark experiment per operation under one semantic group and returns the
combined report.

```mbti
pub async fn run_mare_benchmark(Array[Operation], DecimalSemantics, Array[Int], @model.RunProtocol, UInt64) -> MareBenchmarkReport
```

Each dataset is validated against the oracle before timing. The function does
not abort on failures; callers check `failed_count`. It runs on the `native`
and `js` targets.

```moonbit
async test "mare mark smoke run" {
  let report = @floating_vs_decmial_x.run_mare_benchmark(
    [Divide],
    XCompatible,
    [16],
    @floating_vs_decmial_x.smoke_protocol(),
    42UL,
  )
  inspect(report.failed_count, content="0")
  inspect(report.results[0].timing_scope, content="semantic_equivalent_pipeline")
}
```

## Reports

### `mare_performance_report_document`

`mare_performance_report_document(results, target, run_id)` builds a Plot IR
document with one latency plot per operation and semantic group, and one
X-versus-GDA speedup plot per group.

```mbti
pub fn mare_performance_report_document(Array[PerformanceResult], String, String, validation_count? : Int, failed_count? : Int) -> @ir_model.PlotDocument
```

The corpus summary is total `validation_count + failed_count`, passed
`validation_count` and failed `failed_count`. Because `validation_count`
already includes failures, the summary is only right when `failed_count` is
zero; see the [design page](../design/floating_vs_decmial_x.md#boundaries).

### `mare_performance_report_html`

`mare_performance_report_html` renders the same document as a self-contained
HTML page.

```mbti
pub fn mare_performance_report_html(Array[PerformanceResult], String, String, validation_count? : Int, failed_count? : Int) -> String
```

```moonbit
test "performance report" {
  let result : @floating_vs_decmial_x.PerformanceResult = {
    operation: Add,
    semantics: ExactOverlap,
    timing_scope: "arithmetic_only",
    digits: 16,
    x_median_us: 1.0,
    gda_median_us: 2.0,
    gda_relative_delta_pct: 100.0,
    x_speedup_vs_gda: 2.0,
    decision: "x_faster",
    samples: 60,
  }
  let html = @floating_vs_decmial_x.mare_performance_report_html(
    [result],
    "native",
    "example",
    validation_count=2,
  )
  inspect(html.contains("x_decimal"), content="true")
}
```

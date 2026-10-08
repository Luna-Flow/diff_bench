# dzmingli_vs_floating API

The package `Luna-Flow/diff_bench/dzmingli_vs_floating` compares
`DzmingLi/decimal@0.2.2` with `Luna-Flow/floating/decimal_gda@0.7.1` on
identical decimal inputs, checks both against an exact `BigInt` oracle, and
measures them with Mare Mark. It is a benchmark harness, not a decimal library:
every function aborts on input outside its contract instead of returning a
`Result`, because an invalid fixture is a bug in the harness.

The [tutorial](../tutorial/dzmingli_vs_floating.md) shows the items in use, and
the [design page](../design/dzmingli_vs_floating.md) derives the precision
contract and the oracle. Source: `src/dzmingli_vs_floating/`.

The examples on this page are blackbox tests: they import the package as
`@dzmingli_vs_floating` and `moonbitlang/core/bigint`.

## Neutral decimal model

### `DecimalValue`

`DecimalValue` is the implementation-neutral decimal that every fixture,
oracle result and observation is converted to.

```mbti
pub(all) struct DecimalValue {
  coefficient : @bigint.BigInt
  scale : Int
}
```

A value $(c, s)$ denotes $c \cdot 10^{-s}$. The sign lives in the
coefficient. Values produced by this package have $s \ge 0$; a negative
exponent is multiplied into the coefficient by `parse_decimal_value`. Many
pairs denote the same number, such as $(1200, 2)$ and $(12, 0)$;
`normalize` picks one of them.

### `normalize`

`normalize` removes trailing decimal zeros from the coefficient while the
scale stays non-negative.

```mbti
pub fn normalize(DecimalValue) -> DecimalValue
```

Zero becomes $(0, 0)$. For any other value the result has $s = 0$ or a
coefficient not divisible by $10$. That form is unique for each number, so two
values are equal exactly when their normalized forms are equal (proof in the
[design page](../design/dzmingli_vs_floating.md#correctness-and-invariants)).
Cost: one `BigInt` division per removed zero.

### `canonical_string`

`canonical_string` renders the normalized value in plain positional notation,
without an exponent.

```mbti
pub fn canonical_string(DecimalValue) -> String
```

The string has a leading `-` for negative values, a `0.` prefix and leading
fractional zeros when $|v| < 1$, and no trailing zeros. It is injective on
numbers, so string equality is value equality. This string is the comparison
boundary for every validation in the package.

### `parse_decimal_value`

`parse_decimal_value` reads a finite decimal string into a normalized
`DecimalValue`.

```mbti
pub fn parse_decimal_value(String) -> DecimalValue
```

Accepted syntax: an optional leading sign, digits with at most one `.`, and an
optional exponent `e` or `E` with its own optional sign. Digits are
accumulated into a `BigInt` one at a time, so the parser does not depend on
`BigInt::from_string`. It aborts on an empty digit sequence, an exponent
without digits, `NaN`, `Infinity` or any other character. The exponent is held
in an `Int`.

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
  let v = @dzmingli_vs_floating.parse_decimal_value("-12.3400e1")
  inspect(v.coefficient, content="-1234")
  inspect(v.scale, content="1")
  let wide : @dzmingli_vs_floating.DecimalValue = { coefficient: 1200N, scale: 2 }
  inspect(@dzmingli_vs_floating.normalize(wide).scale, content="0")
  inspect(@dzmingli_vs_floating.canonical_string(v), content="-123.4")
  inspect(@dzmingli_vs_floating.to_oracle_result(wide).canonical, content="12")
}
```

## Exact arithmetic

These functions compute exactly on `DecimalValue`; there is no precision and
no rounding. Results are normalized.

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

`multiply` returns the exact product: coefficients multiply and scales add.

```mbti
pub fn multiply(DecimalValue, DecimalValue) -> DecimalValue
```

### `compare`

`compare` returns `-1`, `0` or `1` as the left operand is less than, equal to
or greater than the right one.

```mbti
pub fn compare(DecimalValue, DecimalValue) -> Int
```

```moonbit
test "exact arithmetic" {
  let a = @dzmingli_vs_floating.parse_decimal_value("1.25")
  let b = @dzmingli_vs_floating.parse_decimal_value("-0.005")
  let show = @dzmingli_vs_floating.canonical_string
  inspect(show(@dzmingli_vs_floating.add(a, b)), content="1.245")
  inspect(show(@dzmingli_vs_floating.subtract(a, b)), content="1.255")
  inspect(show(@dzmingli_vs_floating.multiply(a, b)), content="-0.00625")
  inspect(@dzmingli_vs_floating.compare(a, b), content="1")
}
```

## Reference oracle

The oracle computes the expected result of every benchmarked operation
exactly, with `BigInt` arithmetic only. Its semantics are those of a GDA
context with enough precision and rounding toward zero; the
[design page](../design/dzmingli_vs_floating.md#the-exact-finite-oracle)
states each rule.

### `oracle_multiply`

`oracle_multiply` returns the exact product; it is `multiply` under the
oracle's name.

```mbti
pub fn oracle_multiply(DecimalValue, DecimalValue) -> DecimalValue
```

### `oracle_divide`

`oracle_divide` returns the exact quotient when it has a finite decimal
expansion.

```mbti
pub fn oracle_divide(DecimalValue, DecimalValue) -> DecimalValue
```

It aborts on a zero divisor and on a quotient whose reduced denominator has a
prime factor other than $2$ and $5$ ("repeating decimal in exact decimal
oracle"). Cost: a `BigInt` GCD plus one multiplication by $10$ per fractional
digit of the result.

### `oracle_operation`

`oracle_operation` evaluates a binary or unary `Operation` and returns the
normalized result.

```mbti
pub fn oracle_operation(Operation, DecimalValue, DecimalValue) -> OracleResult
```

It is `oracle_operation3` with a zero third operand, so it gives the wrong
answer for `Fma` unless the addend is zero.

### `oracle_operation3`

`oracle_operation3` evaluates any `Operation`; the third operand is the addend
of `Fma` and is ignored otherwise.

```mbti
pub fn oracle_operation3(Operation, DecimalValue, DecimalValue, DecimalValue) -> OracleResult
```

| Operation | Expected value |
| --- | --- |
| `Add`, `Subtract`, `Multiply` | exact result |
| `Divide` | exact terminating quotient; aborts otherwise |
| `DivideInteger` | quotient truncated toward zero |
| `Remainder` | $a - b \cdot \operatorname{trunc}(a/b)$, with the sign of $a$ |
| `Power` | $a^n$ by repeated multiplication; $n$ must be a non-negative integer |
| `Fma` | $a \cdot b + c$ exactly |
| `SquareRoot` | exact root of a perfect square with an even scale; aborts otherwise |
| `Plus`, `Minus`, `Abs` | $a$, $-a$, $\lvert a \rvert$ |
| `Quantize` | $a$ truncated toward zero to the scale of $b$ |
| `Rescale` | $a$ truncated toward zero to scale $-b$; $b$ must be an integer |
| `ScaleB` | $a \cdot 10^{b}$; $b$ must be an integer |
| `Reduce` | normalized $a$ |
| `ToIntegralExact`, `ToIntegralValue` | $a$ truncated toward zero to an integer |
| `Compare` | `-1`, `0` or `1` as a decimal |
| `Parse`, `Format` | $a$ unchanged |

```moonbit
test "reference oracle" {
  let a = @dzmingli_vs_floating.parse_decimal_value("1.25")
  let b = @dzmingli_vs_floating.parse_decimal_value("8")
  let show = @dzmingli_vs_floating.canonical_string
  inspect(show(@dzmingli_vs_floating.oracle_divide(a, b)), content="0.15625")
  let minus_seven_and_a_half = @dzmingli_vs_floating.parse_decimal_value("-7.5")
  let two = @dzmingli_vs_floating.parse_decimal_value("2")
  let r = @dzmingli_vs_floating.oracle_operation(Remainder, minus_seven_and_a_half, two)
  inspect(r.canonical, content="-1.5")
  let fma = @dzmingli_vs_floating.oracle_operation3(Fma, a, b, two)
  inspect(fma.canonical, content="12")
}
```

## Operations and suites

### `Operation`

`Operation` lists the operation families of the benchmark.

```mbti
pub(all) enum Operation {
  Add
  Subtract
  Multiply
  Divide
  DivideInteger
  Remainder
  Power
  Fma
  SquareRoot
  Plus
  Minus
  Abs
  Quantize
  Rescale
  ScaleB
  Reduce
  ToIntegralExact
  ToIntegralValue
  Compare
  Parse
  Format
}
```

`Parse` and `Format` are identity paths: both adapters return the prepared
left operand, so they measure nothing and are not run by the executables.

### `operation_name`

`operation_name` returns the stable snake-case name used in JSONL records and
fingerprints, such as `"divide_integer"` or `"sqrt"`.

```mbti
pub fn operation_name(Operation) -> String
```

### `OperandShape`

`OperandShape` labels a generated case.

```mbti
pub(all) enum OperandShape {
  Small
  Large
  Boundary
  Cancellation
  Repeating
}
```

The label is serialized into the case and its fingerprint; `generate_cases`
assigns it cyclically by index and it does not change how operands are
generated.

### `TimingScope`

`TimingScope` selects what a timed invocation contains.

```mbti
pub(all) enum TimingScope {
  OperationOnly
  FullPath
}
```

`OperationOnly` times the public operation on operands prepared before timing.
`FullPath` also parses both canonical operand strings, and the addend for
`Fma`, under the prepared context.

### `timing_scope_name`

`timing_scope_name` returns `"arithmetic_only"` or `"full_path"`.

```mbti
pub fn timing_scope_name(TimingScope) -> String
```

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

`default_suite` returns the suite named `"dzmingli-vs-floating-gda"` with all
21 operations, scales `[0, 2, 6, 18, 28]`, `OperationOnly`, 5 warmups and 20
samples. The Mare Mark runners do not read it; their protocol comes from
`default_benchmark_protocol`.

```mbti
pub fn default_suite() -> Suite
```

### `suite_case_count`

`suite_case_count` returns operations × scales × cases per operation.

```mbti
pub fn suite_case_count(Suite, Int) -> Int
```

```moonbit
test "operations and suites" {
  inspect(@dzmingli_vs_floating.operation_name(SquareRoot), content="sqrt")
  inspect(@dzmingli_vs_floating.timing_scope_name(FullPath), content="full_path")
  let suite = @dzmingli_vs_floating.default_suite()
  inspect(@dzmingli_vs_floating.suite_case_count(suite, 4), content="420")
}
```

## Deterministic cases

### `generate_decimal`

`generate_decimal(seed, digits, scale, negative)` builds a decimal string with
exactly `digits` coefficient digits, `scale` of them after the point.

```mbti
pub fn generate_decimal(Int, Int, Int, Bool) -> String
```

Digit $i$ is $1 + ((\mathit{seed} + 7i) \bmod 9)$, so every digit is in
$1..9$: the coefficient has exactly `digits` digits and no trailing zero. When
`scale >= digits` the string starts with `0.` and leading zeros. Aborts if
`digits <= 0` or `scale < 0`.

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
without reading the clock or global random state.

```mbti
pub fn generate_cases(Int, Int, Operation) -> Array[BenchmarkCase]
```

Case $i$ has $1 + ((\mathit{seed} + 11i) \bmod 24)$ digits and scale
$(\mathit{seed} + 5i) \bmod 9$ for both operands. Divisors are not filtered,
so `Divide` cases may not terminate; use them with the adapters, not with
`oracle_divide`.

### `serialize_case`

`serialize_case` joins the version tag `decimal-neutral-v1`, the id, the
operation name, the shape name, both operands and the scale with newlines.

```mbti
pub fn serialize_case(BenchmarkCase) -> String
```

### `fingerprint_case`

`fingerprint_case` hashes `serialize_case` with Mare Mark's
`stable_fingerprint` and returns a `sha256:` string.

```mbti
pub fn fingerprint_case(BenchmarkCase) -> String
```

### `expand_digit_scales`

`expand_digit_scales(sizes, n)` repeats each coefficient size `n` times, so
that Mare Mark creates `n` independent datasets per size.

```mbti
pub fn expand_digit_scales(Array[Int], Int) -> Array[Int]
```

```moonbit
test "deterministic cases" {
  inspect(@dzmingli_vs_floating.generate_decimal(3, 6, 2, true), content="-4297.53")
  let cases = @dzmingli_vs_floating.generate_cases(7, 3, Add)
  inspect(cases[1].left, content="-9753186429753186.429")
  inspect(
    @dzmingli_vs_floating.fingerprint_case(cases[0]) ==
    @dzmingli_vs_floating.fingerprint_case(@dzmingli_vs_floating.generate_cases(7, 3, Add)[0]),
    content="true",
  )
  assert_eq(@dzmingli_vs_floating.expand_digit_scales([4, 16], 2), [4, 4, 16, 16])
}
```

## Fixtures and adapters

### `working_precision`

`working_precision` returns a number of significant digits large enough for
the exact result of an operation on the given operands.

```mbti
pub fn working_precision(Operation, DecimalValue, DecimalValue) -> Int
```

With $d_\ell, d_r$ the digit counts of the coefficients and $s_\ell, s_r$ the
scales:

| Operation | Result |
| --- | --- |
| `Add`, `Subtract` | $\max(d_\ell, d_r) + \lvert s_\ell - s_r \rvert + 2$ |
| `Multiply`, `Fma`, `Power`, `Divide`, `DivideInteger`, `Remainder` | $d_\ell + d_r + 2$ |
| `SquareRoot` and the unary operations | $d_\ell + 2$ |
| `Compare`, `Parse`, `Format` | $\max(d_\ell, d_r) + 1$ |

`prepare_fixture3` adds two guard digits and overrides `Power` and `Fma`; the
[design page](../design/dzmingli_vs_floating.md#precision-contract) proves
which operand classes each bound covers.

### `DecimalFixture`

`DecimalFixture` holds both implementations' operands and contexts, built
before timing.

```mbti
pub struct DecimalFixture {
  left_text : String
  right_text : String
  third_text : String
  operation : Operation
  dz_left : @decimal.Decimal
  dz_right : @decimal.Decimal
  dz_third : @decimal.Decimal
  dz_context : @decimal.Context
  gda_left : @decimal_gda.Decimal
  gda_right : @decimal_gda.Decimal
  gda_third : @decimal_gda.Decimal
  gda_context : @decimal_gda.GdaContext
}
```

`@decimal` is `DzmingLi/decimal` and `@decimal_gda` is
`Luna-Flow/floating/decimal_gda`. The `*_text` fields are the canonical
strings that `FullPath` parses again.

### `prepare_fixture3`

`prepare_fixture3(operation, left, right, third)` chooses the precision $p$,
builds both contexts with precision $p$ and rounding toward zero, and parses
all three canonical strings into both libraries.

```mbti
pub fn prepare_fixture3(Operation, DecimalValue, DecimalValue, DecimalValue) -> DecimalFixture
```

$p$ is $2 d_\ell + 4$ for `Power`,
$d_\ell + d_r + d_t + \lvert s_\ell + s_r - s_t \rvert + 4$ for `Fma`, and
`working_precision(...) + 2` otherwise. Aborts if DzmingLi reports a
conversion-syntax error.

### `prepare_fixture`

`prepare_fixture(operation, left, right)` is `prepare_fixture3` with a zero
third operand.

```mbti
pub fn prepare_fixture(Operation, DecimalValue, DecimalValue) -> DecimalFixture
```

### `dz_from_neutral`

`dz_from_neutral` converts a value to a DzmingLi decimal under
`Context::exact()`.

```mbti
pub fn dz_from_neutral(DecimalValue) -> @decimal.Decimal
```

### `gda_from_neutral`

`gda_from_neutral(value, precision)` parses the canonical string into a GDA
decimal under a context with the given precision and rounding toward zero.

```mbti
pub fn gda_from_neutral(DecimalValue, Int) -> @decimal_gda.Decimal
```

### `DecimalObservation`

`DecimalObservation` is the raw result of one adapter call.

```mbti
pub(all) enum DecimalObservation {
  Dz(@decimal.Decimal)
  Gda(@decimal_gda.GdaOutcome[@decimal_gda.Decimal])
}
```

The GDA variant keeps the whole outcome, including flags and the next
context; validation reads only its value.

### `run_dz`

`run_dz` performs the fixture's operation with DzmingLi on the prepared
operands. This is the `OperationOnly` timed body.

```mbti
pub fn run_dz(DecimalFixture) -> DecimalObservation
```

### `run_dz_full`

`run_dz_full` parses the fixture's three strings under `dz_context` and then
performs the operation. This is the `FullPath` timed body.

```mbti
pub fn run_dz_full(DecimalFixture) -> DecimalObservation
```

### `run_gda`

`run_gda` performs the fixture's operation with floating GDA on the prepared
operands.

```mbti
pub fn run_gda(DecimalFixture) -> DecimalObservation
```

### `run_gda_full`

`run_gda_full` parses the fixture's three strings under `gda_context` and then
performs the operation.

```mbti
pub fn run_gda_full(DecimalFixture) -> DecimalObservation
```

### `canonical_observation`

`canonical_observation` converts an observation to a normalized
`DecimalValue`.

```mbti
pub fn canonical_observation(DecimalObservation) -> DecimalValue
```

DzmingLi results go through `to_sci_string`, GDA results through
`to_string`, and both through `parse_decimal_value`. Exponent, trailing zeros
and status flags are dropped. Aborts on a NaN or infinite result.

```moonbit
test "fixtures and adapters" {
  let a = @dzmingli_vs_floating.parse_decimal_value("1.25")
  let b = @dzmingli_vs_floating.parse_decimal_value("8")
  inspect(@dzmingli_vs_floating.working_precision(Divide, a, b), content="6")
  let fixture = @dzmingli_vs_floating.prepare_fixture(Divide, a, b)
  inspect(fixture.gda_context.precision(), content="8")
  let show = (o : @dzmingli_vs_floating.DecimalObservation) => {
    @dzmingli_vs_floating.canonical_string(
      @dzmingli_vs_floating.canonical_observation(o),
    )
  }
  inspect(show(@dzmingli_vs_floating.run_dz(fixture)), content="0.15625")
  inspect(show(@dzmingli_vs_floating.run_gda(fixture)), content="0.15625")
  inspect(show(@dzmingli_vs_floating.run_gda_full(fixture)), content="0.15625")
}
```

## Mare Mark integration

### `MareDecimalInput`

`MareDecimalInput` is the materialized input of one Mare Mark dataset.

```mbti
pub(all) struct MareDecimalInput {
  left : DecimalValue
  right : DecimalValue
  third : DecimalValue
  operation : Operation
  timing_scope : TimingScope
  digits : Int
  left_scale : Int
  right_scale : Int
}
```

### `PerformanceResult`

`PerformanceResult` summarizes one operation, timing scope and coefficient
size.

```mbti
pub(all) struct PerformanceResult {
  operation : Operation
  timing_scope : TimingScope
  digits : Int
  correctness_valid : Bool
  dz_median_us : Double
  gda_median_us : Double
  gda_relative_delta_pct : Double
  dz_speedup_vs_gda : Double
  decision : String
  samples : Int
}
```

`correctness_valid` is true when every validation at that size passed for both
implementations. Then the medians come from paired confirmatory samples,
`dz_speedup_vs_gda` is the GDA median divided by the DzmingLi median (above
$1$ means DzmingLi is faster), `gda_relative_delta_pct` is the median paired
difference relative to the DzmingLi median, and `decision` is
`"gda_faster"`, `"dzmingli_faster"`, `"equivalent"`, `"invalid"` or
`"unknown"`. Otherwise the medians use each implementation's own valid
samples, the speedup and delta are `0.0` and `decision` is
`"invalid_correctness"`.

### `PerformanceResult::to_json`

`PerformanceResult::to_json` renders a `"comparison"` JSONL record tagged with
the Mare Mark artifact version `mmka_1`.

```mbti
pub fn PerformanceResult::to_json(Self) -> String
```

### `MareBenchmarkReport`

`MareBenchmarkReport` collects the results, the raw JSONL and the validation
counts of a run.

```mbti
pub(all) struct MareBenchmarkReport {
  results : Array[PerformanceResult]
  jsonl : String
  validation_count : Int
  failed_count : Int
}
```

`validation_count` counts every oracle validation, passed or failed.

### `smoke_protocol`

`smoke_protocol` returns a short Mare Mark protocol for tests: 2 warmups,
0.5 ms calibration batches and 3 confirmatory repetitions.

```mbti
pub fn smoke_protocol() -> @model.RunProtocol
```

### `default_benchmark_protocol`

`default_benchmark_protocol` returns the protocol of the published runs: 5
warmups, 5 ms calibration batches, balanced block order with seed
`0xDEC1A1`, outliers reported but not removed, validation of every dataset and
20 confirmatory repetitions.

```mbti
pub fn default_benchmark_protocol() -> @model.RunProtocol
```

### `benchmark_environment`

`benchmark_environment` builds the environment snapshot recorded in the JSONL
from the `MARE_*` environment variables.

```mbti
pub fn benchmark_environment() -> @model.EnvironmentSnapshot
```

It reads `MARE_TARGET`, `MARE_COMPILER`, `MARE_BUILD_MODE`, `MARE_CPU`,
`MARE_DEVICE`, `MARE_FREQUENCY_POLICY`, `MARE_OS`, `MARE_EXECUTION_CONTEXT`
and `MARE_REPOSITORY_STATE`. Missing or empty variables become `unknown`,
`unspecified` or another fixed default; nothing is detected from the host.

### `run_mare_benchmark`

`run_mare_benchmark(operations, scope, digit_scales, protocol, seed)` runs one
Mare Mark experiment per operation and returns the combined report.

```mbti
pub async fn run_mare_benchmark(Array[Operation], TimingScope, Array[Int], @model.RunProtocol, UInt64) -> MareBenchmarkReport
```

Each entry of `digit_scales` is one dataset; repeat sizes with
`expand_digit_scales`. Every dataset is validated against the oracle before it
is timed. The function does not abort on validation failures; callers check
`failed_count`. It needs an async runtime, so it runs on the `native` and `js`
targets.

```moonbit
async test "mare mark smoke run" {
  let report = @dzmingli_vs_floating.run_mare_benchmark(
    [Add],
    OperationOnly,
    [4],
    @dzmingli_vs_floating.smoke_protocol(),
    42UL,
  )
  inspect(report.failed_count, content="0")
  inspect(report.validation_count, content="2")
  inspect(report.results[0].correctness_valid, content="true")
  inspect(report.results[0].to_json().contains("\"type\":\"comparison\""), content="true")
}
```

## Reports

### `mare_performance_report_document`

`mare_performance_report_document(results, target, run_id)` builds a Mare
Mark Plot IR document: one latency plot per operation and timing scope, and
one DzmingLi-versus-GDA speedup plot per timing scope.

```mbti
pub fn mare_performance_report_document(Array[PerformanceResult], String, String, validation_count? : Int, failed_count? : Int) -> @ir_model.PlotDocument
```

Sizes where `correctness_valid` is false keep the GDA latency point but
contribute no DzmingLi point and no speedup point. The corpus summary is total
`validation_count`, passed `validation_count - failed_count` and failed
`failed_count`.

### `mare_performance_report_html`

`mare_performance_report_html` renders the same document as a self-contained
HTML page.

```mbti
pub fn mare_performance_report_html(Array[PerformanceResult], String, String, validation_count? : Int, failed_count? : Int) -> String
```

```moonbit
test "performance report" {
  let result : @dzmingli_vs_floating.PerformanceResult = {
    operation: Add,
    timing_scope: OperationOnly,
    digits: 16,
    correctness_valid: true,
    dz_median_us: 1.0,
    gda_median_us: 2.0,
    gda_relative_delta_pct: 100.0,
    dz_speedup_vs_gda: 2.0,
    decision: "dzmingli_faster",
    samples: 60,
  }
  let html = @dzmingli_vs_floating.mare_performance_report_html(
    [result],
    "native",
    "example",
    validation_count=2,
  )
  inspect(html.contains("Total 2 · passed 2 · failed 0"), content="true")
}
```

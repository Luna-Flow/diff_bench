# floating_vs_decmial_x tutorial

This tutorial shows how to compare `moonbitlang/x/decimal` (X) and floating's
`decimal_gda` (GDA) under each of the two semantic groups, check them against
the oracle, run a small Mare Mark measurement, and reproduce the published
benchmark. Why the groups and precisions are chosen this way is on the
[design page](../design/floating_vs_decmial_x.md).

| I want to | Use |
| --- | --- |
| compare on inputs where both libraries are exact | `semantics=ExactOverlap` |
| make GDA reproduce X's 28-digit truncation | `semantics=XCompatible` |
| check one operation | `prepare_fixture`, `run_x`, `run_gda`, `oracle_operation` |
| check a corpus | `generate_cases` and the loop below |
| time both libraries | `run_mare_benchmark` with `smoke_protocol()` in an `async test` |
| reproduce the published numbers | `moon run --release src/floating_vs_decmial_x/bench --target native` |

## Quick start

The repository is not published on mooncakes; clone it and work inside the
module or a `moon.work` workspace that contains it:

```sh
git clone https://github.com/Luna-Flow/diff_bench.git
cd diff_bench
moon test --target native
```

Import the package in the `moon.pkg` of a package in the module:

```moonbit nocheck
import {
  "Luna-Flow/diff_bench/floating_vs_decmial_x",
}
```

The smallest useful program divides $1$ by $3$ under X's policy in both
libraries:

```moonbit
test "quick start" {
  let one = @floating_vs_decmial_x.parse_decimal_value("1")
  let three = @floating_vs_decmial_x.parse_decimal_value("3")
  let fixture = @floating_vs_decmial_x.prepare_fixture(Divide, one, three, semantics=XCompatible)
  let show = (o : @floating_vs_decmial_x.DecimalObservation) => {
    @floating_vs_decmial_x.canonical_string(@floating_vs_decmial_x.canonical_observation(o))
  }
  inspect(show(@floating_vs_decmial_x.run_x(fixture)), content="0.3333333333333333333333333333")
  inspect(show(@floating_vs_decmial_x.run_gda(fixture)), content="0.3333333333333333333333333333")
}
```

Both return the quotient truncated to 28 fractional digits; GDA gets there with
a `divide` followed by a `quantize`.

## Everyday tasks

### Choose a semantic group

`ExactOverlap` is for inputs whose exact result both libraries represent. GDA
then runs one operation and must return the exact value:

```moonbit
test "exact overlap" {
  let a = @floating_vs_decmial_x.parse_decimal_value("12345.6789")
  let b = @floating_vs_decmial_x.parse_decimal_value("8")
  let fixture = @floating_vs_decmial_x.prepare_fixture(Divide, a, b, semantics=ExactOverlap)
  let gda = @floating_vs_decmial_x.canonical_observation(@floating_vs_decmial_x.run_gda(fixture))
  inspect(@floating_vs_decmial_x.canonical_string(gda), content="1543.2098625")
  inspect(@floating_vs_decmial_x.working_precision(Divide, a, b, semantics=ExactOverlap), content="12")
}
```

`XCompatible` reproduces X's 28-digit truncation. A product with 36
fractional digits is cut to 28 on both sides:

```moonbit
test "x-compatible product" {
  let a : @floating_vs_decmial_x.DecimalValue = { coefficient: 123456789N, scale: 18 }
  let b : @floating_vs_decmial_x.DecimalValue = { coefficient: 987654321N, scale: 18 }
  let fixture = @floating_vs_decmial_x.prepare_fixture(Multiply, a, b, semantics=XCompatible)
  let show = (o : @floating_vs_decmial_x.DecimalObservation) => {
    @floating_vs_decmial_x.canonical_string(@floating_vs_decmial_x.canonical_observation(o))
  }
  inspect(show(@floating_vs_decmial_x.run_x(fixture)), content="0.0000000000000000001219326311")
  inspect(show(@floating_vs_decmial_x.run_gda(fixture)), content="0.0000000000000000001219326311")
}
```

The exact product is $1.21932631112635269 \times 10^{-19}$; truncation keeps
the digits up to $10^{-28}$.

### Check a corpus against the oracle

`oracle_operation` implements X's policy, so it is the reference for both
groups:

```moonbit
test "corpus against the oracle" {
  let ops : Array[@floating_vs_decmial_x.Operation] = [Add, Subtract, Multiply, Divide, Compare]
  let mut checked = 0
  for op in ops {
    for case in @floating_vs_decmial_x.generate_cases(73, 20, op) {
      let left = @floating_vs_decmial_x.parse_decimal_value(case.left)
      let right = @floating_vs_decmial_x.parse_decimal_value(case.right)
      let expected = @floating_vs_decmial_x.oracle_operation(op, left, right).canonical
      let fixture = @floating_vs_decmial_x.prepare_fixture(op, left, right)
      for observation in [
        @floating_vs_decmial_x.run_x(fixture),
        @floating_vs_decmial_x.run_gda(fixture),
      ] {
        let got = @floating_vs_decmial_x.canonical_observation(observation)
        assert_eq(@floating_vs_decmial_x.canonical_string(got), expected)
      }
      checked += 1
    }
  }
  inspect(checked, content="100")
}
```

Generated cases have at most 24 digits, below every division precision, so
the [operand-rounding limitation](../design/floating_vs_decmial_x.md#known-limitation-operand-rounding-in-x-compatible-division)
does not apply to them.

### Run a small Mare Mark measurement

```moonbit
async test "smoke measurement" {
  let report = @floating_vs_decmial_x.run_mare_benchmark(
    [Add, Multiply],
    ExactOverlap,
    [4, 16],
    @floating_vs_decmial_x.smoke_protocol(),
    42UL,
  )
  inspect(report.failed_count, content="0")
  inspect(report.validation_count, content="8")
  inspect(report.results[0].timing_scope, content="arithmetic_only")
}
```

Run it on `native` or `js`; the function is `async`. Each result row holds the
X and GDA medians in microseconds and `x_speedup_vs_gda`, the GDA median over
the X median.

### Reproduce the published benchmark

From the repository root:

```sh
moon run --release src/floating_vs_decmial_x/bench --target native \
  > artifacts/floating_vs_decmial_x/scaling.jsonl
moon run --release src/floating_vs_decmial_x/bench_common --target native \
  > artifacts/floating_vs_decmial_x/common_digits.jsonl
```

The first command measures 1 to 4,096 digits, the second 1, 4, 8, 16, 18 and 28
digits. Both write an HTML report next to the JSONL (see the
[bench page](floating_vs_decmial_x/bench.md)). Set `MARE_CPU`, `MARE_OS`,
`MARE_BUILD_MODE` and the other `MARE_*` variables to record the host; unset
facts are written as `unknown` or `unspecified`. Then render the figure:

```sh
python3 tools/layout_x_decimal.py
```

Read the records by timing scope: `arithmetic_only` is one public operation,
`semantic_equivalent_pipeline` is the full sequence that reproduces X's policy
in GDA. Results from different targets are never combined.

## Going further

**Precision for your own inputs.** For `XCompatible` division
`working_precision` depends on the digit difference of the operands, not on
their length. Inputs longer than that precision are rounded when the fixture
is built (see the [design page](../design/floating_vs_decmial_x.md#known-limitation-operand-rounding-in-x-compatible-division)).
Keep both operands at most $p$ digits long when you need a guaranteed match.

**Interpreting a speedup.** `x_speedup_vs_gda` is a ratio of medians from
paired samples; `decision` applies a 3 % practical threshold to the median
paired difference. Neither is a confidence interval. The
[statistics section](../design/dzmingli_vs_floating.md#paired-statistics) of
the sibling benchmark gives the formulas.

**Sibling package.** [`dzmingli_vs_floating`](dzmingli_vs_floating.md) applies
the same method with an exact oracle, a second timing scope with parsing, and
19 operations.

## Common pitfalls

- `prepare_fixture` and `working_precision` default to `XCompatible`. Pass
  `semantics=ExactOverlap` explicitly when you want the exact group.
- In `XCompatible` division, operands with more significant digits than the
  precision are rounded before GDA divides them: GDA can then return $0.5$
  where X returns $0.4999999999999999999999999999$, and the timing compares
  shorter GDA operands with full X operands.
- `x_from_neutral` aborts for scales above 28; X cannot hold such values.
- The HTML summary line is correct only for runs without failures; read
  `validation_count` and `failed_count` from the report instead.
- `BigInt::from_string` is wrong for long strings on `wasm-gc` in the current
  `moonbitlang/core`. Build long test values with `parse_decimal_value` or
  `BigInt` arithmetic instead, as the test
  `division precision follows the requested semantic contract` does: it
  builds its 4,096-nines operand by multiplication and expects the working
  precision $4096 + 1 + 2 = 4099$ on every target.
- The published numbers for X were measured with `moonbitlang/x@0.4.46`; the
  module now depends on `0.5.5`, and the JSONL implementation record still
  names `0.4.46`.

## Next steps

- [API reference](../api/floating_vs_decmial_x.md) for every item.
- [Design](../design/floating_vs_decmial_x.md) for the semantic groups and the
  precision proofs.
- [Performance analysis](../performance/floating_vs_decmial_x.md) for the
  measured results.
- [Benchmark executables](floating_vs_decmial_x/bench.md) and the
  [common-digit executable](floating_vs_decmial_x/bench_common.md).

# dzmingli_vs_floating tutorial

This tutorial shows how to check `DzmingLi/decimal` and floating's
`decimal_gda` against the exact oracle, first for one operation and then for a
deterministic corpus, how to run a small Mare Mark measurement from a test,
and how to reproduce the published benchmark and its official decTest audit.
The mathematics behind the checks is on the
[design page](../design/dzmingli_vs_floating.md).

| I want to | Use |
| --- | --- |
| check one operation in both libraries | `prepare_fixture`, `run_dz`, `run_gda`, `oracle_operation` |
| compare a result with the oracle | `canonical_string(canonical_observation(o))` against `.canonical` |
| check a whole deterministic corpus | `generate_cases` and the loop below |
| include parsing in the timed work | `run_dz_full`, `run_gda_full` (`FullPath`) |
| time both libraries | `run_mare_benchmark` with `smoke_protocol()` in an `async test` |
| reproduce the published numbers | `moon run --release src/dzmingli_vs_floating/bench --target native` |

## Quick start

`diff_bench` is a GitHub-only repository; it is not published on mooncakes.
Clone it and work inside the module, or add the clone to a `moon.work`
workspace:

```sh
git clone https://github.com/Luna-Flow/diff_bench.git
cd diff_bench
moon test --target native
```

A package inside the module imports the benchmark package in its `moon.pkg`:

```moonbit nocheck
import {
  "Luna-Flow/diff_bench/dzmingli_vs_floating",
}
```

The smallest useful program checks one division in both libraries against the
oracle:

```moonbit
test "quick start" {
  let a = @dzmingli_vs_floating.parse_decimal_value("1.25")
  let b = @dzmingli_vs_floating.parse_decimal_value("8")
  let fixture = @dzmingli_vs_floating.prepare_fixture(Divide, a, b)
  let expected = @dzmingli_vs_floating.oracle_operation(Divide, a, b).canonical
  let show = (o : @dzmingli_vs_floating.DecimalObservation) => {
    @dzmingli_vs_floating.canonical_string(@dzmingli_vs_floating.canonical_observation(o))
  }
  inspect(expected, content="0.15625")
  inspect(show(@dzmingli_vs_floating.run_dz(fixture)), content="0.15625")
  inspect(show(@dzmingli_vs_floating.run_gda(fixture)), content="0.15625")
}
```

The three `inspect` lines are the output: the oracle and both libraries agree on
$1.25 / 8 = 0.15625$.

## Everyday tasks

### Check every operation family on one input

`oracle_operation3` and `prepare_fixture3` take a third operand for `Fma`;
the other operations ignore it. The loop below checks 16 operations on inputs
that suit them all: a perfect square for `SquareRoot`, an integer exponent for
`Power`, and a zero shift for `ScaleB`.

```moonbit
test "every operation on one input" {
  let ops : Array[@dzmingli_vs_floating.Operation] = [
    Add, Subtract, Multiply, Divide, DivideInteger, Remainder, Power, Fma,
    SquareRoot, Plus, Minus, Abs, Reduce, ToIntegralExact, ToIntegralValue,
    Compare,
  ]
  let left = @dzmingli_vs_floating.parse_decimal_value("144")
  let two = @dzmingli_vs_floating.parse_decimal_value("2")
  let third = @dzmingli_vs_floating.parse_decimal_value("0.5")
  let mut agreed = 0
  for op in ops {
    let expected = @dzmingli_vs_floating.oracle_operation3(op, left, two, third).canonical
    let fixture = @dzmingli_vs_floating.prepare_fixture3(op, left, two, third)
    for observation in [
      @dzmingli_vs_floating.run_dz(fixture),
      @dzmingli_vs_floating.run_gda(fixture),
    ] {
      let got = @dzmingli_vs_floating.canonical_observation(observation)
      if @dzmingli_vs_floating.canonical_string(got) == expected {
        agreed += 1
      }
    }
  }
  inspect(agreed, content="32")
}
```

All 16 operations agree in both libraries ($16 \times 2 = 32$).

### Time with or without parsing

`run_dz` and `run_gda` use operands parsed before timing; `run_dz_full` and
`run_gda_full` parse the canonical strings first. Both paths must give the same
value, which is what the `FullPath` timing scope relies on:

```moonbit
test "both timing paths agree" {
  let a = @dzmingli_vs_floating.parse_decimal_value("123456789.000000018")
  let b = @dzmingli_vs_floating.parse_decimal_value("-0.987654321")
  let fixture = @dzmingli_vs_floating.prepare_fixture(Multiply, a, b)
  let show = (o : @dzmingli_vs_floating.DecimalObservation) => {
    @dzmingli_vs_floating.canonical_string(@dzmingli_vs_floating.canonical_observation(o))
  }
  let fast = show(@dzmingli_vs_floating.run_gda(fixture))
  inspect(fast, content="-121932631.112635286777777778")
  inspect(show(@dzmingli_vs_floating.run_gda_full(fixture)) == fast, content="true")
  inspect(show(@dzmingli_vs_floating.run_dz_full(fixture)) == fast, content="true")
  inspect(@dzmingli_vs_floating.oracle_operation(Multiply, a, b).canonical == fast, content="true")
}
```

### Validate a deterministic corpus

`generate_cases` gives the same operands for the same seed. Divisions in such
a corpus may not terminate, so the loop checks the operations whose results are
always exact:

```moonbit
test "deterministic corpus" {
  let ops : Array[@dzmingli_vs_floating.Operation] = [Add, Subtract, Multiply, Compare]
  let mut checked = 0
  for op in ops {
    for case in @dzmingli_vs_floating.generate_cases(73, 20, op) {
      let left = @dzmingli_vs_floating.parse_decimal_value(case.left)
      let right = @dzmingli_vs_floating.parse_decimal_value(case.right)
      let expected = @dzmingli_vs_floating.oracle_operation(op, left, right).canonical
      let fixture = @dzmingli_vs_floating.prepare_fixture(op, left, right)
      let gda = @dzmingli_vs_floating.canonical_observation(@dzmingli_vs_floating.run_gda(fixture))
      let dz = @dzmingli_vs_floating.canonical_observation(@dzmingli_vs_floating.run_dz(fixture))
      assert_eq(@dzmingli_vs_floating.canonical_string(gda), expected)
      assert_eq(@dzmingli_vs_floating.canonical_string(dz), expected)
      checked += 1
    }
  }
  inspect(checked, content="80")
}
```

### See what insufficient precision looks like

The fixture precision is chosen so that no result is rounded. If it were too
small, rounding toward zero would shorten the result and the oracle comparison
would fail. Here a product with six significant digits is computed in a
four-digit context with floating's `decimal_gda` package (imported as
`@decimal_gda`):

```moonbit
test "too little precision is detected" {
  let a = @dzmingli_vs_floating.parse_decimal_value("123.45")
  let b = @dzmingli_vs_floating.parse_decimal_value("6.7")
  let context = @decimal_gda.context(precision=4, rounding=@decimal_gda.GdaRoundingMode::Down)
  let product = @decimal_gda.multiply(
    @dzmingli_vs_floating.gda_from_neutral(a, 8),
    @dzmingli_vs_floating.gda_from_neutral(b, 8),
    context,
  )
  let got = @dzmingli_vs_floating.canonical_observation(Gda(product))
  inspect(@dzmingli_vs_floating.canonical_string(got), content="827.1")
  inspect(@dzmingli_vs_floating.oracle_operation(Multiply, a, b).canonical, content="827.115")
  inspect(@dzmingli_vs_floating.working_precision(Multiply, a, b), content="9")
}
```

`working_precision` asks for 9 digits, enough for the 6 digits of $827.115$.

### Run a small Mare Mark measurement

`run_mare_benchmark` validates every dataset against the oracle and then times
both libraries. It is `async`, so call it from an `async test` on the `native`
or `js` target. `smoke_protocol` keeps the run short:

```moonbit
async test "smoke measurement" {
  let report = @dzmingli_vs_floating.run_mare_benchmark(
    [Add, Multiply],
    FullPath,
    @dzmingli_vs_floating.expand_digit_scales([16], 2),
    @dzmingli_vs_floating.smoke_protocol(),
    7UL,
  )
  inspect(report.failed_count, content="0")
  inspect(report.validation_count, content="8")
  inspect(report.results.length(), content="2")
  inspect(report.results[0].samples, content="6")
}
```

Two operations × two datasets × two implementations give eight validations.
Each result row pairs 2 datasets × 3 smoke repetitions = 6 samples; its
latencies are `report.results[i].dz_median_us` and `gda_median_us`.

### Reproduce the published benchmark

Run from the repository root on the native release target:

```sh
moon run --release src/dzmingli_vs_floating/bench --target native \
  | sed -n '/^{/p' > artifacts/dzmingli_vs_floating/scaling.jsonl
moon run --release src/dzmingli_vs_floating/bench_common --target native \
  | sed -n '/^{/p' > artifacts/dzmingli_vs_floating/common_digits.jsonl
```

The scaling run takes a long time and exits nonzero after writing its complete
report, because DzmingLi fails validation from 4,096 digits on. Check that every
Mare Mark summary record says `"complete":true` before reading the numbers, and
set `MARE_CPU`, `MARE_OS` and `MARE_BUILD_MODE` to record the host. The
[bench page](dzmingli_vs_floating/bench.md) describes the outputs.

The official GDA decTest audit runs separately:

```sh
sh tools/run_dzmingli_dectest_audit.sh
```

It downloads the decTest archive, checks its SHA-256, runs the shared operation
files against both libraries and exits nonzero while DzmingLi's known `toSci`
failures remain.

## Going further

**Your own operand classes.** `prepare_fixture3` chooses the precision from
the operands. The [precision contract](../design/dzmingli_vs_floating.md#precision-contract)
is proven for the generated classes only; for new inputs, check that the exact
result fits. If it does not, validation fails rather than passing silently,
so a failing new fixture may point at the fixture before it points at a
library.

**Adding an operation.** Add a constructor to `Operation`, its name in
`operation_name`, a rule in `oracle_operation3`, a precision line in
`working_precision` (or an override in `prepare_fixture3`), the calls in both
adapters, and an input rule in the Mare Mark materializer. Add a test that
checks the new operation against the oracle on edge values before timing it.

**Figures.** The Python layouts in `tools/` read the JSONL, build Mare Mark
Plot IR, and render PNG, PDF and SVG with Matplotlib:

```sh
python3 tools/plot_dzmingli_benchmark.py \
  artifacts/dzmingli_vs_floating/scaling.jsonl \
  --output artifacts/dzmingli_vs_floating/main \
  --ir-output artifacts/dzmingli_vs_floating/main.ir.json
```

`tools/plot_dzmingli_supplementary_benchmark.py` draws the supplementary
figure the same way.

**Sibling packages.** [`floating_vs_decmial_x`](floating_vs_decmial_x.md)
applies the same method to `moonbitlang/x/decimal`. The libraries come from
[floating](https://lunaflow.cn/en/floating/) and the runner from
[mare_mark](https://lunaflow.cn/en/mare_mark/).

## Common pitfalls

- `oracle_divide` aborts on a repeating quotient such as $1/3$. Use only
  divisors whose reduced denominator is a product of $2$s and $5$s.
- `oracle_operation` passes a zero addend, so it is wrong for `Fma`; use
  `oracle_operation3`.
- The comparison ignores exponents and flags: GDA's `1.20` and DzmingLi's
  `1.2` agree. Use the decTest audit for representation and conditions.
- `Parse` and `Format` return the prepared operand on both sides; they do not
  measure parsing or formatting.
- `validation_count` includes failed validations; passed validations are
  `validation_count - failed_count`.
- `run_mare_benchmark` does not abort on validation failures; check
  `failed_count`. The executables do abort, after writing their report.
- The executables do real work only on `--target native`; on other targets they
  print a message and exit.
- Do not build long test inputs with `BigInt::from_string` on `wasm-gc`: in the
  current `moonbitlang/core` it returns wrong values for strings of thousands of
  digits (4,096 nines parse to a 4,094-digit number). `parse_decimal_value`
  accumulates digits itself and is not affected. The package test
  `division precision covers exact terminating quotients` uses `from_string`
  but only asserts a lower bound, so it passes on every target.
- DzmingLi aborts on products above about 21,475 digits (see the
  [design page](../design/dzmingli_vs_floating.md#operation-specific-size-ceilings));
  keep multiplication inputs at or below 10,000 digits.

## Next steps

- [API reference](../api/dzmingli_vs_floating.md) for every item.
- [Design](../design/dzmingli_vs_floating.md) for the oracle, the precision
  contract and the statistics.
- [Performance analysis](../performance/dzmingli_vs_floating.md) for the
  measured results.
- [Benchmark executables](dzmingli_vs_floating/bench.md) and the
  [common-digit executable](dzmingli_vs_floating/bench_common.md).

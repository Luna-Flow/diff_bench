# diff_bench

Differential correctness and performance benchmarks for Luna-Flow MoonBit
packages. Each benchmark runs two decimal libraries on identical inputs,
checks both against an independent exact `BigInt` oracle, and measures them
with [Mare Mark](https://lunaflow.cn/en/mare_mark/) only where the results are
right. The Luna-Flow subject is the `decimal_gda` package of
[floating](https://lunaflow.cn/en/floating/).

Version `0.1.0`. This is a GitHub-only reference project: it is not published
on mooncakes and is not meant as a runtime dependency.

## Install

Clone the repository and work inside the module, or add the clone to a
`moon.work` workspace:

```sh
git clone https://github.com/Luna-Flow/diff_bench.git
cd diff_bench
moon test --target native
```

## Example

A package inside the module imports
`"Luna-Flow/diff_bench/dzmingli_vs_floating"` in its `moon.pkg` and checks one
division in both libraries against the oracle:

```moonbit
test "one division, two libraries, one oracle" {
  let a = @dzmingli_vs_floating.parse_decimal_value("1.25")
  let b = @dzmingli_vs_floating.parse_decimal_value("8")
  let fixture = @dzmingli_vs_floating.prepare_fixture(Divide, a, b)
  let expected = @dzmingli_vs_floating.oracle_operation(Divide, a, b).canonical
  let dz = @dzmingli_vs_floating.canonical_observation(@dzmingli_vs_floating.run_dz(fixture))
  let gda = @dzmingli_vs_floating.canonical_observation(@dzmingli_vs_floating.run_gda(fixture))
  inspect(expected, content="0.15625")
  inspect(@dzmingli_vs_floating.canonical_string(dz) == expected, content="true")
  inspect(@dzmingli_vs_floating.canonical_string(gda) == expected, content="true")
}
```

## Packages

| Package | Purpose |
| --- | --- |
| `dzmingli_vs_floating` | `DzmingLi/decimal@0.2.2` versus floating GDA on 19 exact operations, with an exact-finite oracle and two timing scopes |
| `dzmingli_vs_floating/bench` | native scaling run, 1 to 20,000 coefficient digits |
| `dzmingli_vs_floating/bench_common` | native run at 1, 4, 8, 16, 18 and 28 digits |
| `floating_vs_decmial_x` | `moonbitlang/x/decimal` versus floating GDA under the `exact_overlap` and `x_compatible` semantic groups |
| `floating_vs_decmial_x/bench` | native scaling run, 1 to 4,096 coefficient digits |
| `floating_vs_decmial_x/bench_common` | native run at 1, 4, 8, 16, 18 and 28 digits |

The root package `Luna-Flow/diff_bench` holds only the template function
`hello`. Raw JSONL, HTML reports, Plot IR and figures are kept under
`artifacts/<package>/`; `tools/` holds the Python figure layouts and the
official decTest audit (`tools/run_dzmingli_dectest_audit.sh`).

Reproduce the published runs from the repository root:

```sh
moon run --release src/dzmingli_vs_floating/bench --target native \
  | sed -n '/^{/p' > artifacts/dzmingli_vs_floating/scaling.jsonl
moon run --release src/floating_vs_decmial_x/bench --target native \
  > artifacts/floating_vs_decmial_x/scaling.jsonl
```

The figure layouts need Python 3 with Matplotlib, for example
`python3 tools/layout_x_decimal.py`.

## Toolchain

MoonBit `moonc` 0.10 or later with the `moon.mod` and `moon.pkg` manifests.
The executables and the asynchronous Mare Mark runs need the `native` target.

Known issue: on `native` and `js` the test
`division precision follows the requested semantic contract` fails with
`4099 != 4097`. Its expected value was recorded on `wasm-gc`, where
`BigInt::from_string` in `moonbitlang/core` misparses long inputs; `4099` is
the correct value. Other known limitations of the X comparison are listed in
its [design page](doc/manual/design/floating_vs_decmial_x.md#boundaries).

## Documentation

The manual is published at
[lunaflow.cn/en/diff_bench](https://lunaflow.cn/en/diff_bench/) with Chinese
and Japanese translations. Its English source starts at
[doc/manual/index.md](doc/manual/index.md): API, tutorial and design pages for
every package, and the performance analysis of both comparisons
([DzmingLi](doc/manual/performance/dzmingli_vs_floating.md),
[X](doc/manual/performance/floating_vs_decmial_x.md)). New readers start with
the [`dzmingli_vs_floating` tutorial](doc/manual/tutorial/dzmingli_vs_floating.md).

## Contributing

See the [contribution guidelines](doc/manual/contributing.md). Common commands:

```sh
just fmt
just check-all
just test
just ready
```

## License

Apache-2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).

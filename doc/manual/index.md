# diff_bench

`diff_bench` contains differential correctness and performance benchmarks for Luna-Flow MoonBit packages.

`floating_vs_decmial_x` is a GitHub-only reference benchmark. It is not published to Mooncakes or intended as a downstream runtime dependency.

## Benchmarks

- `dzmingli_vs_floating` compares `DzmingLi/decimal@0.2.2` with
  `Luna-Flow/floating/decimal_gda@0.7.1` against an exact `BigInt` oracle. The
  [design report](design/dzmingli_vs_floating.md) states the measurement
  contract and the correctness findings, the
  [performance analysis](performance/dzmingli_vs_floating.md) gives the
  measured latencies, and the [tutorial](tutorial/dzmingli_vs_floating.md)
  reproduces the run.
- `floating_vs_decmial_x` compares `moonbitlang/x/decimal@0.4.46` with
  `Luna-Flow/floating/decimal_gda@0.7.1`. The
  [design report](design/floating_vs_decmial_x.md) explains the semantic groups
  and summarizes the results, the
  [performance analysis](performance/floating_vs_decmial_x.md) interprets them,
  and the [tutorial](tutorial/floating_vs_decmial_x.md) reproduces the run.

## Artifacts

Raw JSONL records, self-contained HTML reports, Plot IR and the rendered PNG,
PDF and SVG figures are kept in the repository under `artifacts/<package>/`,
outside the manual. The performance pages link to them.

## Contributing

The [contribution guidelines](contributing.md) cover code style, naming,
testing, dependencies and the release checklist.

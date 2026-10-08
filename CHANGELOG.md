# Changelog

All notable changes to `Luna-Flow/diff_bench` are recorded here.

## Unreleased

### Changed

- Migrated to MoonBit `moonc` 0.10. The manifests were already `moon.mod` and
  `moon.pkg`; no public API changed.
- Bumped `moonbitlang/async` from 0.20.1 to 0.22.4 and `moonbitlang/x` from
  0.4.46 to 0.5.5.
- Bumped `Luna-Flow/floating` from 0.7.1 to 0.8.0 (`Luna-Flow/mare_mark`
  stays at 0.3.0). The benchmarks use only the `decimal_gda` module functions
  and `GdaContext`, which 0.8.0 does not change, so no code change is needed.
- `floating_vs_decmial_x` calls `Compare::compare` explicitly for X decimals
  instead of the deprecated promoted method.
- Sources reformatted with the MoonBit 0.10 formatter.
- Blackbox tests qualify package items (`@dzmingli_vs_floating.normalize`,
  `@diff_bench.hello`, ...), as MoonBit 0.10 requires.
- `.gitignore` ignores local AI agent state.

### Documentation

- Documentation rewritten (API, tutorial and design pages for every package,
  including the bench executables and the root package) with zh_CN and ja_JP
  translations. The design pages derive the oracle, the working-precision
  contracts with their error bounds, and the paired statistics.
- The performance pages state the measurement environment and that the
  published runs predate the migration.
- Manual brought to the Luna-Flow documentation standard: the index has
  Install, Pages, exported items, reading paths and Validation; every API page
  has Purpose and Importing; every tutorial has an "I want to" table; every
  design page has Constraints and Alternatives rejected.
- The design pages show that the decision (median of paired differences) and
  the speedup column (ratio of medians) can disagree, as 22 published
  DzmingLi records at 1 to 16 digits do, and that the X executables rotate the
  scale profiles across sizes.
- Corrected performance claims: the GDA range at 1,024 digits starts at
  0.131 µs (compare), `x_compatible` multiplication is now reported, and only
  `exact_overlap` multiplication shows a size-stable ratio.

### Fixed

- The test `division precision follows the requested semantic contract`
  expects the `ExactOverlap` precision `4099` (4096 + 1 + 2) instead of
  `4097`, and builds its 4,096-digit operands by multiplication instead of
  `BigInt::from_string`, which truncates long strings on `wasm-gc`. It passes
  on `native`, `js`, `wasm` and `wasm-gc` (#3).

### Known issues

- `floating_vs_decmial_x` rounds GDA operands longer than the
  `x_compatible` division precision when it builds fixtures, so that contract
  is not guaranteed for such operands and the `x_compatible` division timings
  from 64 digits on compare unequal work.
- The `floating_vs_decmial_x` HTML corpus summary overstates totals when a run
  has validation failures, and its Mare Mark implementation record still names
  `moonbitlang/x@0.4.46`.
- The `floating_vs_decmial_x` executables choose scale pairs from the global
  dataset id, so neighbouring sizes of a curve use different scale profiles.

## 0.1.0

- `dzmingli_vs_floating`: `DzmingLi/decimal@0.2.2` versus
  `Luna-Flow/floating/decimal_gda@0.7.1` on 19 exact operations with an
  exact-finite `BigInt` oracle, `arithmetic_only` and `full_path` timing
  scopes, and the official decTest audit.
- `floating_vs_decmial_x`: `moonbitlang/x/decimal` versus floating GDA under
  the `exact_overlap` and `x_compatible` semantic groups.
- Both benchmarks run on `Luna-Flow/mare_mark@0.3.0` and keep their JSONL,
  HTML reports, Plot IR and figures under `artifacts/`.

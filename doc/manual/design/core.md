# core design

## Design goal

The root package keeps the layout of the Luna-Flow repository template: a
package at the source root with one public function and one test, so that
`moon check`, `moon test` and `moon info` have something to work on in every
repository.

## Design decisions

- **Benchmarks are subpackages.** Each comparison lives in its own package
  with its own dependencies, so `floating_vs_decmial_x` builds without
  `DzmingLi/decimal` and the other way around, and each can be documented and
  run alone.
- **Nothing is shared through the root.** The neutral decimal model is copied
  into each benchmark package instead of being moved here. That keeps each
  package self-contained at the cost of duplicated code; the copies are
  byte-identical (`canonical.mbt`, `parse.mbt`, `generator.mbt`).

## Boundaries

The root package provides no benchmark functionality and no shared helpers.

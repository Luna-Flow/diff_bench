# core design

## Design goal

The root package keeps the layout of the Luna-Flow repository template: a
package at the source root with one public function and one test, so that
`moon check`, `moon test` and `moon info` have something to work on in every
repository.

## Constraints

- Every Luna-Flow repository keeps a package at the source root, so that the
  template's `moon check`, `moon test` and `moon info` workflow applies.
- Each benchmark must build with only its own dependencies.

## Main design decisions

- **Benchmarks are subpackages.** Each comparison lives in its own package
  with its own dependencies, so `floating_vs_decmial_x` builds without
  `DzmingLi/decimal` and the other way around, and each can be documented and
  run alone.
- **Nothing is shared through the root.** The neutral decimal model is copied
  into each benchmark package instead of being moved here. That keeps each
  package self-contained at the cost of duplicated code; the copies are
  byte-identical (`canonical.mbt`, `parse.mbt`, `generator.mbt`).

## Alternatives rejected

- **A shared neutral-model package at the root.** Rejected: both benchmarks
  would then depend on one more package, and a change made for one comparison
  could silently change the other. The duplicated files are small and checked
  by their own tests in each package.
- **No root package at all.** Rejected: the template's tooling and CI expect a
  package at the source root.

## Boundaries

The root package provides no benchmark functionality and no shared helpers.

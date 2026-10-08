# Contribution guidelines

## Code style

- Format all MoonBit code with `just fmt`.
- Keep files organized by package boundary first, then by behavior.
- Keep comments short and technical. Explain contracts, invariants, or non-obvious implementation choices.

## Naming conventions

- Bindings and functions: lowercase with underscores, such as `scaled_value`.
- Types and traits: PascalCase, such as `Solver`.
- Files: lowercase with underscores, named after concrete behavior.
- Error codes, if introduced, should use uppercase with underscores and an `E_` prefix.

## Testing

- Add or update tests whenever behavior changes.
- Use package-local `*_test.mbt` or `*_wbtest.mbt` files as appropriate.
- Run `just test` for normal validation and `just ready` before opening a PR.
  Run `moon test --target native` as well: the asynchronous Mare Mark tests do
  not run on the default `wasm-gc` target.
- Build long `BigInt` test values with arithmetic or `parse_decimal_value`, not
  `BigInt::from_string`, which misparses long strings on `wasm-gc`.
- A new benchmarked operation needs an oracle rule, a working-precision bound
  that holds the exact result, and a test against the oracle before it is
  timed.
- Regenerate public interface files with `just info` when public APIs change.

## Documentation

- The English manual is in `doc/manual`: one API, tutorial and design page per
  package, named after the package path, plus the performance chapter.
- Keep MoonBit examples compiling; fence intentionally partial snippets as
  `moonbit nocheck`.
- After changing English pages, run `lunadoc update` and update the Chinese and
  Japanese catalogs in `doc/locale`.

## Dependencies

- Update dependencies through `just update-deps`.
- Review `moon.mod` diffs before committing.
- Avoid changing dependency or version declarations in unrelated PRs.

## Commit guidelines

- Use concise English Conventional Commit messages, such as `fix: handle empty input`.
- Keep each commit focused on one logical change.

## Release checklist

- Update `version` in `moon.mod`.
- Ensure README and docs reflect the current package.
- Run `just ready`.
- Trigger the `publish-package` GitHub Actions workflow with the exact `moon.mod` version.

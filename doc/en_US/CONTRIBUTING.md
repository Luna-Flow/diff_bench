# Contribution Guidelines

View this guide in [zh_CN](../zh_CN/CONTRIBUTING.md) | [ja_JP](../ja_JP/CONTRIBUTING.md)

## Code Style

- Format all MoonBit code with `just fmt`.
- Keep files organized by package boundary first, then by behavior.
- Keep comments short and technical. Explain contracts, invariants, or non-obvious implementation choices.

## Naming Conventions

- Bindings and functions: lowercase with underscores, such as `scaled_value`.
- Types and traits: PascalCase, such as `Solver`.
- Files: lowercase with underscores, named after concrete behavior.
- Error codes, if introduced, should use uppercase with underscores and an `E_` prefix.

## Testing

- Add or update tests whenever behavior changes.
- Use package-local `*_test.mbt` or `*_wbtest.mbt` files as appropriate.
- Run `just test` for normal validation and `just ready` before opening a PR.
- Regenerate public interface files with `just info` when public APIs change.

## Dependencies

- Update dependencies through `just update-deps`.
- Review `moon.mod` diffs before committing.
- Avoid changing dependency or version declarations in unrelated PRs.

## Commit Guidelines

- Use concise English Conventional Commit messages, such as `fix: handle empty input`.
- Keep each commit focused on one logical change.

## Release Checklist

- Update `version` in `moon.mod`.
- Ensure README and docs reflect the current package.
- Run `just ready`.
- Trigger the `publish-package` GitHub Actions workflow with the exact `moon.mod` version.

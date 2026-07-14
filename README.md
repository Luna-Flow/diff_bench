# Luna-Flow MoonBit Repository Template

This repository is the standard starter layout for Luna-Flow MoonBit packages.

## First-Time Setup

1. Rename the module in `moon.mod`.
2. Update `version`, `repository`, `keywords`, and `description` in `moon.mod`.
3. Replace this README with the package-specific overview.
4. Replace the placeholder documentation under `doc/`.
5. Replace the placeholder source package under `src/`.
6. Update `NOTICE` if the generated repository needs a more specific copyright notice.
7. Configure the `LUNA_MOONCAKE` repository secret before using the publish workflow.

## Development

Use `just` for local workflows:

```bash
just fmt
just check
just test
just ready
just update-deps
```

`just ready` is the default pre-PR workflow: it formats, checks, refreshes public interface files, and runs coverage-enabled tests.

## Documentation

Documentation lives under `doc/` and is organized by locale:

- `doc/en_US`
- `doc/zh_CN`
- `doc/ja_JP`

Each package or subsystem directory should contain:

- `api.md`
- `tutorial.md`
- `design.md`

## Publishing

Publishing is handled by `.github/workflows/publish.yml`.

Before dispatching the workflow:

1. Set `version` in `moon.mod` to the exact version to publish.
2. Run `just ready`.
3. Trigger the `publish-package` workflow manually.
4. Enter the exact `moon.mod` version as `release_version`.

The workflow validates the input version, checks the package with frozen dependencies, and publishes through `moon publish --frozen`.

# Running and Reproducing

From the repository root, run either benchmark command documented in [api.md](api.md). Set known host facts with `MARE_CPU`, `MARE_OS`, `MARE_BUILD_MODE`, and other `MARE_*` overrides; missing facts remain `unknown` or `unspecified`. `arithmetic_only` measures the direct public operation, while `semantic_equivalent_pipeline` includes X-compatible precision and truncation processing. Keep results from different MoonBit targets separate.

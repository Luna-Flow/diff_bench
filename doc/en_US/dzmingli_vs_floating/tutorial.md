# Reproducing the Comparison

Run from the repository root on the native release target:

```sh
sh tools/run_dzmingli_dectest_audit.sh
moon run --release src/dzmingli_vs_floating/bench --target native \
  | sed -n '/^{/p' > artifacts/dzmingli_vs_floating/scaling.jsonl
moon run --release src/dzmingli_vs_floating/bench_common --target native \
  | sed -n '/^{/p' > artifacts/dzmingli_vs_floating/common_digits.jsonl
```

The decTest command intentionally exits nonzero while DzmingLi has known
`toSci` failures. The scaling command also exits nonzero after writing its
complete report when exact-finite validation failures are present. Confirm all
summary records have `"complete":true` before interpreting performance.

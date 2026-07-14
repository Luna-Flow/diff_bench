# 复现实验

在仓库根目录运行：

```sh
sh tools/run_dzmingli_dectest_audit.sh
moon run --release src/dzmingli_vs_floating/bench --target native \
  | sed -n '/^{/p' > artifacts/mare_mark_dzmingli_vs_floating_extended.jsonl
moon run --release src/dzmingli_vs_floating/bench_common --target native \
  > artifacts/mare_mark_dzmingli_vs_floating_common_digits.jsonl
```

DzmingLi 存在已知 `toSci` 失败，因此 decTest 命令会非零退出。scaling runner
也会在完整写出报告后，因 exact-finite 校验失败而非零退出。分析性能前应确认所有
summary 均含 `"complete":true`。

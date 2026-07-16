# 比較の再現方法

リポジトリのルートで実行します。

```sh
sh tools/run_dzmingli_dectest_audit.sh
moon run --release src/dzmingli_vs_floating/bench --target native \
  | sed -n '/^{/p' > artifacts/dzmingli_vs_floating/scaling.jsonl
moon run --release src/dzmingli_vs_floating/bench_common --target native \
  | sed -n '/^{/p' > artifacts/dzmingli_vs_floating/common_digits.jsonl
```

DzmingLi には既知の `toSci` 失敗があるため decTest は非ゼロ終了します。scaling も
完全なレポートを書き出した後、exact-finite 検証失敗により非ゼロ終了します。
性能を解釈する前に、すべての summary が `"complete":true` であることを確認します。

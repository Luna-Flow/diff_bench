# core API

The package `Luna-Flow/diff_bench` at the source root (`src/`) holds the
module's template placeholder. The benchmarks live in the subpackages
[`dzmingli_vs_floating`](dzmingli_vs_floating.md) and
[`floating_vs_decmial_x`](floating_vs_decmial_x.md).

## `hello`

`hello` returns the fixed greeting `"hello from Luna-Flow"`.

```mbti
pub fn hello() -> String
```

It takes no input, has no side effects and never fails. It exists so that the
root package has a public item and a test; no benchmark uses it.

```moonbit
test "hello" {
  inspect(@diff_bench.hello(), content="hello from Luna-Flow")
}
```

# core tutorial

This page shows how to call the root package and where to go instead for real
work: the root package `Luna-Flow/diff_bench` contains only the template
function `hello`.

## Quick start

Inside the module, import the root package in `moon.pkg`:

```text
import {
  "Luna-Flow/diff_bench",
}
```

Then call it:

```moonbit
test "root package" {
  let greeting = @diff_bench.hello()
  inspect(greeting.length(), content="20")
  inspect(greeting, content="hello from Luna-Flow")
}
```

## Everyday tasks

There are none in this package. To compare decimal libraries, start with the
[`dzmingli_vs_floating` tutorial](dzmingli_vs_floating.md) or the
[`floating_vs_decmial_x` tutorial](floating_vs_decmial_x.md).

## Common pitfalls

- In a blackbox test the function must be qualified: `@diff_bench.hello()`.
  MoonBit 0.10 warns about the unqualified form.

## Next steps

- [core API](../api/core.md) and [core design](../design/core.md).
- The [manual overview](../index.md) lists every package.

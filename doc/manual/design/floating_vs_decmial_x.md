# floating_vs_decmial_x design

## Design goal

The package compares `moonbitlang/x/decimal` (X) and
`Luna-Flow/floating/decimal_gda@0.7.1` (GDA) on the same inputs. The two
libraries do not implement the same arithmetic: X keeps at most 28 fractional
digits and truncates, GDA rounds to a significant-digit precision chosen by a
context. A fair comparison therefore has to fix a semantic contract first, make
both libraries meet it, prove that they meet it, and only then measure.

The [API page](../api/floating_vs_decmial_x.md) lists the items, the
[tutorial](../tutorial/floating_vs_decmial_x.md) runs them, and the measured
numbers are in the [performance chapter](../performance/floating_vs_decmial_x.md).
The method shared with the DzmingLi benchmark (oracle verdicts, canonical
form, paired statistics) is derived on the
[dzmingli_vs_floating design page](dzmingli_vs_floating.md); this page states
what differs.

## Mathematical background

### Two decimal models

An X decimal is a pair $(c, s)$ with $0 \le s \le 28$ denoting
$c \cdot 10^{-s}$; `Decimal::new` rejects other scales. Its operations are

$$
\begin{aligned}
a \cdot b &= \operatorname{trunc}_{28}\bigl(c_\ell c_r 10^{-(s_\ell + s_r)}\bigr)
  \quad\text{(exact when } s_\ell + s_r \le 28\text{)}, \\
a / b &= \Bigl\lfloor\!\Bigl\lfloor \frac{c_\ell 10^{\,28 - s_\ell + s_r}}{c_r} \Bigr\rfloor\!\Bigr\rfloor \cdot 10^{-28},
\end{aligned}
$$

where $\lfloor\!\lfloor \cdot \rfloor\!\rfloor$ is integer division truncating
toward zero and $\operatorname{trunc}_k$ truncates toward zero to $k$
fractional digits, as defined on the
[DzmingLi design page](dzmingli_vs_floating.md#precision-and-rounding-toward-zero).
Addition, subtraction and comparison are exact. Because $s_\ell \le 28$, the
exponent $28 - s_\ell + s_r$ is never negative, so

$$
a / b = \operatorname{trunc}_{28}(a / b)
$$

exactly: X's quotient is the true quotient truncated to 28 fractional digits.

A GDA operation in a context of precision $p$ with rounding `Down` returns
$\operatorname{round}_p(x)$, the exact result truncated to $p$ significant
digits; `quantize(y, 10^{-28})` in the same context returns
$\operatorname{trunc}_{28}(y)$ when the result fits in $p$ digits.

### Nested truncation

Two facts about truncation carry the proofs below.

**Lemma 1.** For $t \ge k$ and every real $x$,
$\operatorname{trunc}_k(\operatorname{trunc}_t(x)) = \operatorname{trunc}_k(x)$.

*Proof.* Let $x \ge 0$ (the negative case is symmetric) and
$G_j = 10^{-j}\mathbb{Z}$. $\operatorname{trunc}_j(x)$ is the largest point of
$G_j$ not above $x$. Since $G_k \subseteq G_t$, the point
$z = \operatorname{trunc}_k(x)$ lies in $G_t$ and $z \le x$, so
$z \le \operatorname{trunc}_t(x) \le x$. The largest point of $G_k$ below
$\operatorname{trunc}_t(x)$ is therefore at least $z$ and at most the largest
point of $G_k$ below $x$, which is $z$. $\square$

**Lemma 2.** For integers $N$ and $A, B > 0$,
$\lfloor\!\lfloor \lfloor\!\lfloor N / A \rfloor\!\rfloor / B \rfloor\!\rfloor = \lfloor\!\lfloor N / (AB) \rfloor\!\rfloor$.

*Proof.* For $N \ge 0$ write $N = qA + r$ with $0 \le r < A$ and $q = uB + v$
with $0 \le v < B$. Then $N = uAB + (vA + r)$ and
$0 \le vA + r \le (B-1)A + A - 1 < AB$, so $u = \lfloor N/(AB) \rfloor$.
Truncation toward zero is odd in $N$, which gives the negative case. $\square$

## Design decisions

### Two semantic groups

**Problem.** For multiplication and division the libraries' native results
differ as soon as a result needs more than 28 fractional digits, and timing
two different computations says nothing. **Options.** Restrict the benchmark to
inputs where both are exact; force GDA to reproduce X's policy; force X to
reproduce GDA's. **Choice.** Two groups, reported separately:
`ExactOverlap` restricts the inputs, `XCompatible` makes GDA reproduce X's
policy with an extra `quantize`. **Why.** X has no context to configure, so
only the GDA side can adapt; and the cost of that adaptation is part of what a
GDA user pays for X's semantics. The two groups carry different timing scopes,
`arithmetic_only` and `semantic_equivalent_pipeline`, and are never
aggregated.

### One oracle for both groups

The oracle implements X's policy: exact addition, subtraction and comparison,
$\operatorname{trunc}_{28}$ of the exact product when its scale exceeds 28,
and $\operatorname{trunc}_{28}$ of the quotient. For division with
$k = 28 + s_r - s_\ell$ it returns
$\lfloor\!\lfloor c_\ell 10^{k} / c_r \rfloor\!\rfloor$ when $k \ge 0$ and
$\lfloor\!\lfloor \lfloor\!\lfloor c_\ell / 10^{-k} \rfloor\!\rfloor / c_r \rfloor\!\rfloor$
otherwise, which equals
$\lfloor\!\lfloor c_\ell / (10^{-k} c_r) \rfloor\!\rfloor$ by Lemma 2 (taking
the sign of $c_r$ into $N$). Both cases are
$\operatorname{trunc}_{28}(a / b) \cdot 10^{28}$.

In `ExactOverlap` the truncation is the identity on every generated result, so
the same oracle returns the exact value:

- multiplication fixtures use scale pairs with $s_\ell + s_r = 14 \le 28$;
- division fixtures divide an integer by $2$, $4$, $5$, $8$ or $25$, whose
  reciprocals $5 \cdot 10^{-1}$, $25 \cdot 10^{-2}$, $2 \cdot 10^{-1}$,
  $125 \cdot 10^{-3}$ and $4 \cdot 10^{-2}$ have at most three fractional
  digits;
- addition, subtraction and comparison are exact by definition.

### Precision contracts

The GDA precision $p$ is `working_precision(op, ℓ, r, semantics)` with no
guard digits added. With $d_\ell, d_r$ the coefficient digit counts and
$m = \max(d_\ell, d_r) + |s_\ell - s_r|$:

$$
\begin{aligned}
\textbf{Add/Subtract:}\quad & \text{result} < 10^{m+1} &&\Rightarrow p = m + 2 \\
\textbf{Multiply:}\quad & |c_\ell c_r| < 10^{d_\ell + d_r} &&\Rightarrow p = d_\ell + d_r + 1 \\
\textbf{Divide, ExactOverlap:}\quad & |c_\ell| \cdot \{5, 25, 2, 125, 4\} < 10^{d_\ell + 3}
  &&\Rightarrow p = d_\ell + d_r + 2 \ge d_\ell + 3 \\
\textbf{Compare:}\quad & \text{operands only} &&\Rightarrow p = \max(d_\ell, d_r) + 1
\end{aligned}
$$

so every `ExactOverlap` result, and the `XCompatible` product before
quantization, is exact in GDA. The `XCompatible` product is then quantized to
$10^{-28}$ when $s_\ell + s_r > 28$; the quantized coefficient has fewer digits
than the exact one, so `quantize` succeeds and returns
$\operatorname{trunc}_{28}$ of the exact product, which is X's product.

For `XCompatible` division the precision is

$$
p = \max(1, I) + 30, \qquad I = d_\ell - s_\ell - d_r + s_r + 1 .
$$

$I$ bounds the number of integer digits of the quotient:

$$
|a| < 10^{\,d_\ell - s_\ell}, \quad |b| \ge 10^{\,d_r - 1 - s_r}
\quad\Rightarrow\quad
|a / b| < 10^{\,d_\ell - s_\ell - d_r + s_r + 1} = 10^{I} .
$$

`divide` returns $\operatorname{round}_p(a/b)$. If $|a/b| \ge 1$ it has at
most $I$ integer digits, so at least $p - I \ge 30$ fractional digits survive;
if $|a/b| < 1$ every kept digit is fractional and at least $p \ge 31$ of them
survive. In both cases $\operatorname{round}_p(a/b) = \operatorname{trunc}_t(a/b)$
on a grid with $t \ge 30$, and Lemma 1 gives

$$
\operatorname{quantize}\bigl(\operatorname{round}_p(a/b),\ 10^{-28}\bigr)
= \operatorname{trunc}_{28}\bigl(\operatorname{trunc}_t(a/b)\bigr)
= \operatorname{trunc}_{28}(a/b) .
$$

The quantized coefficient has at most $I + 28 \le p - 2$ digits, so `quantize`
does not raise an invalid operation. The two extra digits beyond the 28 are
guard digits; Lemma 1 needs none, but they keep the contract independent of
how the quotient's last digit is produced.

This derivation assumes that `divide` receives the exact operands $a$ and $b$.
The next section shows when the fixture breaks that assumption.

### Known limitation: operand rounding in X-compatible division

`prepare_fixture` parses the GDA operands with
`Decimal::from_string(text, precision=p)`, which rounds half-even to $p$
significant digits. For `XCompatible` division $p$ depends on the digit
difference $I$, not on the operand lengths, so operands longer than $p$ digits
are rounded before the timed division runs. Two consequences follow.

1. **Correctness is not guaranteed by construction.** With operands rounded
   to relative error at most $\tfrac12 10^{1-p}$ each, the computed quotient
   differs from $a/b$ by up to about $|a/b| \cdot 10^{1-p} < 10^{I + 1 - p} \le 10^{-29}$,
   which can move a quotient across a multiple of $10^{-28}$. For example
   $a = 4\underbrace{9\cdots9}_{59}$ and $b = 10^{60}$ give $p = 31$; GDA parses
   $a$ as $5 \cdot 10^{59}$ and returns $0.5$, while X and the oracle return
   $0.4999999999999999999999999999$. The published corpora pass validation
   because their quotients stay away from such boundaries; that is an
   empirical result for the recorded seed.
2. **The timed work differs.** The fixtures pair operands with the same digit
   count $D$ and $p \le 51$, so from $D = 64$ on GDA divides operands of at
   most 51 digits while X divides the full $D$-digit operands. The
   `x_compatible` division timings at 64 digits and above therefore do not
   compare equal work. The common-digit run ($D \le 28 < p$) is not affected.

Parsing the operands with a precision of at least $\max(d_\ell, d_r)$ and
dividing in a context of precision $p$ would remove both effects. The
benchmark code is unchanged on this branch; the limitation is recorded here and
in the [performance chapter](../performance/floating_vs_decmial_x.md).

### Fixtures excluded from timing

Conversions to X and GDA values, the $10^{-28}$ quantum, the context,
validation and canonicalization are all built or run outside timing. The timed
body is `run_x` or `run_gda`: one public operation, plus the `quantize` step in
the `XCompatible` pipeline.

### Paired statistics

The pairing, the relative delta $\delta$ (here relative to the X median), the
$3\,\%$ decision threshold and the speedup ratio are those of the
[DzmingLi benchmark](dzmingli_vs_floating.md#paired-statistics), with X as the
baseline: `x_speedup_vs_gda` above $1$ means X is faster.

## Correctness and invariants

- Canonical form and the soundness of the zero tolerance are proved on the
  [DzmingLi design page](dzmingli_vs_floating.md#correctness-and-invariants);
  the neutral-model code is identical.
- `ExactOverlap`: every generated result is exact in both libraries and equal
  to the oracle, by the precision table and the identity of
  $\operatorname{trunc}_{28}$ on those results.
- `XCompatible` multiplication: X, GDA and the oracle all return
  $\operatorname{trunc}_{28}$ of the exact product.
- `XCompatible` division: X and the oracle return
  $\operatorname{trunc}_{28}(a/b)$ for all inputs. GDA does so whenever its
  operands have at most $p$ significant digits (Lemma 1); longer operands are
  the known limitation above.
- Comparison: X's `Compare::compare` returns the sign of a coefficient
  comparison at a common scale, which `normalize_order` maps to $\{-1, 0, 1\}$;
  GDA's `compare` returns the same values as decimals.

## Alternatives rejected

- **A single "fair" semantics for all operations.** Rejected: there is none
  that both libraries implement natively for products and quotients beyond 28
  fractional digits.
- **Making X imitate GDA.** Rejected: X has no precision or rounding context,
  so it would need extra rescaling outside its public API.
- **Comparing with a tolerance of one unit in the 28th place.** Rejected: both
  sides truncate deterministically, so exact agreement is required and
  achievable.
- **One combined score per operation.** Rejected: `arithmetic_only` and
  `semantic_equivalent_pipeline` time different work.

## Boundaries

- Only add, subtract, multiply, divide and compare are measured. X has no
  context, flags, special values or exponent cohorts, so none of those are
  compared.
- The `XCompatible` division contract holds only for operands that GDA parses
  exactly; see the known limitation.
- The HTML corpus summary reports total `validation_count + failed_count` and
  passed `validation_count`. Mare Mark's `validation_count` already includes
  failures, so the summary overstates both numbers whenever a run has
  failures. The published runs had none.
- The Mare Mark implementation record names `moonbitlang/x@0.4.46`, while the
  module now depends on `moonbitlang/x@0.5.5`; the published measurements were
  taken with 0.4.46.
- `BigInt::from_string` returns wrong values for long inputs on the `wasm-gc`
  target of the current `moonbitlang/core`; a string of 3,584 nines already
  parses wrongly, and 4,096 nines parse to a 4,094-digit number. The package
  does not use it; the test
  `division precision follows the requested semantic contract` does, and its
  expected value `4097` was recorded from that wrong parse. The correct value is
  `4099`, which the `native` and `js` targets compute.
- The executables run on the `native` target only, and results from different
  targets are never combined.

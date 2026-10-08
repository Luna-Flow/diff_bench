# dzmingli_vs_floating design

## Design goal

The package answers two questions about `DzmingLi/decimal@0.2.2` and
`Luna-Flow/floating/decimal_gda@0.7.1`: do they compute the same exact decimal
results, and how fast do they compute them as coefficients grow to thousands of
digits? Speed is only reported where both answers are right, so the design is
built around a correctness check that cannot be fooled by the libraries
agreeing with each other.

The [API page](../api/dzmingli_vs_floating.md) lists the items, and the
[tutorial](../tutorial/dzmingli_vs_floating.md) runs them. Measured numbers
are in the [performance chapter](../performance/dzmingli_vs_floating.md).

## Mathematical background

### Decimal values

A finite decimal is a pair $(c, s) \in \mathbb{Z} \times \mathbb{Z}$ that
denotes

$$
v(c, s) = c \cdot 10^{-s}.
$$

The map $v$ is not injective: $(c, s)$ and $(10c, s + 1)$ denote the same
number. GDA arithmetic keeps such pairs apart (the exponent is part of the
result), while the benchmark compares numbers. It therefore needs a canonical
representative of each class; the package uses the pair with $s \ge 0$ and the
fewest trailing zeros in $c$.

For $c \ne 0$ write $d(c)$ for the number of decimal digits of $|c|$, so that

$$
10^{d(c) - 1} \le |c| < 10^{d(c)} .
$$

`working_precision` computes $d$ as the length of the decimal string of
$|c|$, which gives $d(0) = 1$.

### Precision and rounding toward zero

A GDA context with precision $p$ represents exactly the numbers
$c \cdot 10^{e}$ with $|c| < 10^{p}$ and $e$ in the exponent range. An
operation computes the exact result $x$ and rounds it to such a number. With
rounding mode `Down` (toward zero) the result is

$$
\operatorname{round}_p(x) = \operatorname{sgn}(x)\,
\bigl\lfloor |x| \cdot 10^{\,p - E(x)} \bigr\rfloor \cdot 10^{\,E(x) - p},
\qquad E(x) = \lfloor \log_{10} |x| \rfloor + 1 ,
$$

so $|\operatorname{round}_p(x)| \le |x|$, with equality exactly when $x$ has at
most $p$ significant digits. The same truncation at a fixed number $k$ of
fractional digits is written

$$
\operatorname{trunc}_k(x) = \operatorname{sgn}(x)\,\bigl\lfloor |x| \cdot 10^{k} \bigr\rfloor \cdot 10^{-k} .
$$

### Differential testing with a reference oracle

Let $I_1, I_2$ be the implementations under test, $O$ an oracle and
$\kappa$ a canonicalization map into a set where equality is decidable. For an
input $x$ the verdict of implementation $k$ is

$$
\operatorname{valid}_k(x) \iff \kappa(I_k(x)) = \kappa(O(x)) .
$$

Pairwise differential testing checks only
$\kappa(I_1(x)) = \kappa(I_2(x))$. That check is blind to common-mode errors,
where both implementations share a wrong result, and when it fails it does not
say which side is wrong. With an oracle each implementation is judged on its
own, and a disagreement between the two is explained by the verdicts.

## Design decisions

### Three implementations, two of them measured

**Problem.** The benchmark has to separate "fast" from "fast and wrong".
**Options.** Pairwise agreement between the libraries; one library as the
reference for the other; an independent oracle. **Choice.** An independent
exact oracle over `BigInt`, run outside timing on every dataset
(`ValidationCoverage::EveryDataset`). **Why.** The oracle is small enough to
review line by line, shares no code with either library, and it found the 108
DzmingLi failures from 4,096 digits on, which pairwise agreement would have
reported only as "the libraries differ". A size enters the speedup plots only
when every validation at that size passed for both implementations.

### A neutral representation and a zero tolerance

**Problem.** The two libraries print results differently (exponent notation,
trailing zeros, sign of zero), and approximate comparisons would hide real
errors. **Choice.** Every result is parsed into `DecimalValue` and compared by
`canonical_string` equality, a tolerance of exactly zero. **Why.** All
benchmarked operations have an exactly representable result under the
precision contract below, so a correct implementation must reproduce it
digit for digit; the soundness argument is in
[Correctness and invariants](#correctness-and-invariants). The price is that
the comparison ignores the exponent cohort and the status flags; the official
decTest audit (`tools/run_dzmingli_dectest_audit.sh`) covers those.

### The exact-finite oracle

The oracle uses only integer operations on coefficients.

Addition and subtraction align both operands to $s = \max(s_\ell, s_r)$:

$$
c_\ell 10^{-s_\ell} \pm c_r 10^{-s_r}
= \bigl(c_\ell 10^{s - s_\ell} \pm c_r 10^{s - s_r}\bigr)\, 10^{-s} .
$$

Multiplication multiplies coefficients and adds scales. Division writes the
quotient as a fraction of integers and reduces it,

$$
\frac{c_\ell 10^{-s_\ell}}{c_r 10^{-s_r}} = \frac{N}{M},\quad
N = c_\ell 10^{s_r},\ M = c_r 10^{s_\ell},\quad
N' = \frac{N}{g},\ M' = \frac{|M|}{g},\ g = \gcd(N, M),
$$

and accepts it only if $M'$ has no prime factor other than $2$ and $5$. It then
finds the least $k$ with $M' \mid N' 10^{k}$ and returns
$(N' 10^{k} / M',\ k)$. Integer division, remainder, power, square root of
perfect squares, FMA and the unary operations follow from these rules; the
table on the [API page](../api/dzmingli_vs_floating.md#oracle_operation3) lists
them.

The truncating rules (`DivideInteger`, `Quantize`, `Rescale`,
`ToIntegralExact`, `ToIntegralValue`) truncate toward zero because
`BigInt` division does. GDA's `quantize`, `rescale` and `to_integral_*`
round with the context's mode, so both contexts use `Down`; any other mode
would make the oracle wrong for those operations. In the published fixtures
these operations are exact anyway (see the next decision).

### Precision contract

**Problem.** Every operation must be performed at a precision $p$ that holds
the exact result, so that rounding never happens and the zero tolerance is
fair. A larger $p$ is not free: the work of a GDA division can grow with the
precision, so an oversized $p$ could time work that the result does not need.
**Choice.** $p$ is computed per fixture from the operands, as the smallest
simple bound on the number of digits of the exact result plus guard digits:
`working_precision(op, ℓ, r) + 2`, with overrides for `Power` and `Fma`.
**Why.** The derivations below show the bound holds for every operand class the
runners generate, and that it also holds every operand exactly, so parsing at
$p$ never rounds.

Write $d_\ell, d_r, d_t$ for the operand digit counts and
$m = \max(d_\ell, d_r) + |s_\ell - s_r|$. The runners use these operands:
`Add`, `Subtract`, `Multiply`, `Fma`, `Quantize` and `Compare` take generated
operands with scales from the profiles $(0, 2)$, $(8, 18)$, $(28, 0)$;
`Divide`, `DivideInteger` and `Remainder` divide a generated operand with scale
$0$, $8$ or $28$ by $2$, $8$ or $25$; `Power` squares (exponent $2$);
`SquareRoot` takes the square of a generated integer; `Quantize` uses the
quantum $10^{-s_\ell}$, `Rescale` the exponent $-s_\ell$ and `ScaleB` the
shift $0$; the remaining unary operations take integers.

$$
\begin{aligned}
\textbf{Add/Subtract:}\quad &
|c_\ell 10^{s-s_\ell} \pm c_r 10^{s-s_r}| < 10^{m} + 10^{m} \le 10^{m+1}
&&\Rightarrow\ \le m + 1 \text{ digits},\ p = m + 4 \\
\textbf{Multiply:}\quad & |c_\ell c_r| < 10^{d_\ell + d_r}
&&\Rightarrow\ \le d_\ell + d_r,\ p = d_\ell + d_r + 4 \\
\textbf{Power}\ (n = 2):\quad & |c_\ell^2| < 10^{2 d_\ell}
&&\Rightarrow\ \le 2 d_\ell,\ p = 2 d_\ell + 4 \\
\textbf{Fma:}\quad & |c_\ell c_r 10^{\sigma - s_\ell - s_r} + c_t 10^{\sigma - s_t}|
< 10^{m'+1},\ m' = \max(d_\ell + d_r, d_t) + |s_\ell + s_r - s_t|
&&\Rightarrow\ p = d_\ell + d_r + d_t + |s_\ell + s_r - s_t| + 4 \ge m' + 1 \\
\textbf{Divide}\ (b \in \{2, 8, 25\}):\quad &
\tfrac{1}{2} = 5 \cdot 10^{-1},\ \tfrac{1}{8} = 125 \cdot 10^{-3},\ \tfrac{1}{25} = 4 \cdot 10^{-2}
&&\Rightarrow\ \le d_\ell + 3,\ p = d_\ell + d_r + 4 \ge d_\ell + 5 \\
\textbf{DivideInteger:}\quad & |\operatorname{trunc}(a/b)| \le |a| < 10^{d_\ell - s_\ell}
&&\Rightarrow\ \le d_\ell \\
\textbf{Remainder:}\quad & |r| \le |a|,\ \text{scale}(r) = s_\ell
&&\Rightarrow\ \le d_\ell \\
\textbf{SquareRoot:}\quad & c_\ell = g^2,\ d(g) \le \lceil d_\ell / 2 \rceil
&&\Rightarrow\ p = d_\ell + 4 \\
\textbf{Unary group:}\quad & |\text{result coefficient}| \le |c_\ell|
&&\Rightarrow\ \le d_\ell,\ p = d_\ell + 4 \\
\textbf{Compare:}\quad & \text{result} \in \{-1, 0, 1\}
&&\Rightarrow\ p = \max(d_\ell, d_r) + 3
\end{aligned}
$$

Every $p$ in the table is at least $\max(d_\ell, d_r, d_t)$, so the operands
themselves parse exactly. The `Power` and `Fma` overrides exist because
`working_precision` alone gives $d_\ell + d_r + 2$, which is $d_\ell + 3$ for
the exponent $2$ and too small to hold a square.

The contract is proven for these operand classes, not for every input. For a
general terminating divisor $q = 2^{\alpha}$ the quotient coefficient is
$c_\ell \cdot 5^{\alpha}$, which has about $d_\ell + 0.699\alpha$ digits,
while the bound grows only by $d_r \approx 0.301\alpha + 1$. At $\alpha = 13$
the bound fails: $1 / 8192 = 0.0001220703125$ needs $10$ digits, and
$p = 1 + 4 + 4 = 9$. Such a fixture is not silently accepted; it is rejected
by the oracle comparison, as the next section shows.

### Timing scopes

`OperationOnly` (`arithmetic_only`) times one public operation on operands that
were parsed before timing. `FullPath` (`full_path`) also parses the canonical
operand strings under the prepared context, which is what a caller that
receives text pays. Both scopes run the same datasets with the same
fingerprints, so their numbers describe the same inputs. Context construction,
canonicalization, validation and reporting stay outside both scopes.

### Paired statistics

Mare Mark records, for every dataset $j$, repetition $r$ and block $b$, one
calibrated latency per implementation. The package pairs DzmingLi and GDA
samples that share $(j, r, b)$ and forms differences

$$
\Delta_i = t^{\mathrm{GDA}}_i - t^{\mathrm{DZ}}_i .
$$

If a sample is modelled as $t = \mu_{\mathrm{impl}} + \beta_b + \varepsilon$,
with $\beta_b$ a drift shared by the block (frequency changes, cache state),
then $\Delta_i = \mu_{\mathrm{GDA}} - \mu_{\mathrm{DZ}} + (\varepsilon - \varepsilon')$:
the block effect cancels. `BalancedBlocks` alternates which implementation runs
first, so order effects cancel on average as well. The reported quantities are

$$
\delta = 100 \cdot \frac{\operatorname{median}_i \Delta_i}{\operatorname{median}_i t^{\mathrm{DZ}}_i}\ \%,
\qquad
\text{speedup} = \frac{\operatorname{median}_i t^{\mathrm{GDA}}_i}{\operatorname{median}_i t^{\mathrm{DZ}}_i},
$$

and the decision is `gda_faster` when $\delta \le -3$, `dzmingli_faster` when
$\delta \ge 3$, and `equivalent` otherwise. Medians have a breakdown point of
50 %, so the outliers that Mare Mark reports but does not remove cannot move
them far. The $3\,\%$ threshold is a practical-significance margin, not a
hypothesis test, and the report carries no confidence interval.[^iqr]

[^iqr]: Mare Mark's `compare_paired` stores the interquartile range of the
    $\Delta_i$ as its interval. It describes the spread of the paired
    differences, not the uncertainty of the median.

With three datasets per size and 20 confirmatory repetitions each, a valid size
has 60 pairs.

### Operation-specific size ceilings

DzmingLi's `digit_count` evaluates `bit_length * 30103` in a 32-bit `Int`.
The product overflows when

$$
\text{bit\_length} > \frac{2^{31} - 1}{30103} \approx 71\,337
\quad\Longleftrightarrow\quad
\text{digits} \gtrsim 71\,337 \cdot \log_{10} 2 \approx 21\,475 .
$$

A product of two $n$-digit operands has up to $2n$ digits, so multiplication,
FMA and squaring can cross the limit from $n \approx 10\,738$. The scaling
runner therefore stops all operations at 10,000 digits and runs only add,
subtract, divide and compare at 16,384 and 20,000 digits. These are analytic
bounds from the overflow condition; runs at 32,768 and 65,536 digits reproduced
the abort.

## Correctness and invariants

**Canonical form.** For $c \ne 0$, `normalize` returns $(c', s')$ with
$s' \ge 0$ and ($s' = 0$ or $10 \nmid c'$), and $v(c', s') = v(c, s)$ because
each step replaces $(10q, s)$ by $(q, s - 1)$. Two such pairs denote the same
number only if they are equal:

$$
\begin{aligned}
c_1 10^{-s_1} = c_2 10^{-s_2},\ s_1 < s_2
&\ \Rightarrow\ c_2 = c_1 10^{\,s_2 - s_1} \\
&\ \Rightarrow\ 10 \mid c_2 \text{ and } s_2 > 0 ,
\end{aligned}
$$

which contradicts the normal form of $(c_2, s_2)$; and $s_1 = s_2$ forces
$c_1 = c_2$. `canonical_string` writes the sign, the digits of $|c'|$ and the
point position $s'$, all of which are determined by the number, so string
equality is number equality.

**Oracle division.** $N'/M'$ is in lowest terms. If $M' \mid N' 10^{k}$ then,
since $\gcd(M', N') = 1$, $M' \mid 10^{k} = 2^k 5^k$, so $M'$ has no prime
factor other than $2$ and $5$. Conversely, if $M' = 2^{\alpha} 5^{\beta}$, the
least such $k$ is $\max(\alpha, \beta)$. The oracle checks the factorization
before the loop, so the loop terminates, and the returned scale is the
shortest exact one.

**Integer square root.** The oracle iterates

$$
x_{k+1} = \Bigl\lfloor \frac{x_k + \lfloor n / x_k \rfloor}{2} \Bigr\rfloor,
\qquad x_0 = 10^{\lceil D/2 \rceil} > \sqrt{n},
$$

where $D$ is the digit count of $n$. By the AM-GM inequality
$(x + n/x)/2 \ge \sqrt{n}$, so every iterate is at least
$\lfloor \sqrt{n} \rfloor$; while $x_k > \lfloor \sqrt{n} \rfloor$ we have
$n / x_k < x_k$ and hence $x_{k+1} < x_k$. The sequence decreases strictly
until it reaches $\lfloor \sqrt{n} \rfloor$, where the loop stops. The oracle
then requires $x^2 = n$, so a non-square input aborts instead of producing a
rounded root.

**Soundness of the zero tolerance.** Let $x$ be the exact result and $p$ the
fixture precision.

1. If $x$ has at most $p$ significant digits, a conforming GDA operation returns
   a number equal to $x$, because $x$ is its own correctly rounded value in
   every rounding mode. Then $\kappa(I(x)) = \kappa(O(x))$: a correct
   implementation is never rejected.
2. If $x$ has more than $p$ digits, rounding toward zero gives
   $|\operatorname{round}_p(x)| < |x|$, so the canonical strings differ and the
   validation fails: insufficient precision is never accepted.
3. Equality of canonical strings is equality of numbers, so no wrong result is
   ever accepted.

The precision contract establishes the premise of (1) for every generated
operand class. Outside those classes (2) still holds, which makes the check
fail-closed.

**Determinism.** Operands are derived from Mare Mark's seeded
`derive_seed(seed, "<operation>:<digits>", profile)`, never from the clock, so
the same seed reproduces the same corpus and the same fingerprints.
`generate_decimal` uses only the digits $1..9$; generated coefficients
therefore have exactly the requested number of digits and no trailing zeros.

**Cost of the oracle.** With $n$-digit coefficients, addition is dominated by
the alignment multiplication by $10^{|s_\ell - s_r|}$, multiplication by one
`BigInt` product, and division by a GCD and $\max(\alpha, \beta)$
multiplications by $10$, where $M' = 2^{\alpha} 5^{\beta}$. All of it runs
outside the timed region.

## Alternatives rejected

- **Pairwise agreement only.** Rejected: it cannot attribute a disagreement
  and misses shared errors.
- **One library as the oracle for the other.** Rejected: the GDA library is
  one of the subjects, and the benchmark found DzmingLi failures that would
  then be indistinguishable from GDA failures.
- **Comparison with a tolerance** (ulps or relative error). Rejected: every
  benchmarked result is exact in decimal, so any nonzero tolerance would only
  hide errors.
- **A fixed large precision** such as $10^5$ digits. Rejected: it can inflate
  division work beyond the result and couples timing to an arbitrary
  constant.
- **Random operands per run.** Rejected: results must be reproducible and
  fingerprints stable across timing scopes.
- **Scaling benchmarks for `exp`, `ln` and `log10`.** Rejected: identity
  fixtures would not exercise their algorithms, and general results need an
  independent high-precision transcendental oracle. They are covered by the
  decTest audit only.

## Boundaries

- The package checks numeric values only. Exponent cohorts, trailing zeros of
  results, status flags, NaN, infinities and signed zero are outside the
  comparison; the decTest audit covers them.
- Division is exercised with the terminating divisors $2$, $8$ and $25$ only.
  Repeating quotients and large denominators are not benchmarked, and the
  oracle rejects repeating quotients.
- `Parse` and `Format` are identity paths. They do not test GDA formatting; the
  decTest audit records DzmingLi's 329 `toSci` failures separately.
- `OperandShape` is a label; the corpus is three deterministic scale profiles
  per size, not a random distribution.
- The precision contract is proven for the generated operand classes listed
  above, not for arbitrary inputs.
- The executables run on the `native` target only; other targets print a
  message and exit.
- `DzmingLi/decimal@0.2.2` is deprecated in favour of
  `moonbit-community/decimal`; the benchmark keeps it pinned for a
  historical comparison.

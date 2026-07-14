# Design and Performance Report

## Contract

Both libraries consume identical coefficient-and-scale fixtures. `arithmetic_only`
times only the public operation; `full_path` additionally parses both canonical
operand strings. Validation, canonicalization, calibration, and reporting stay
outside timing. Division uses exact terminating divisors. Performance is paired
only where both implementations pass the independent exact-finite `BigInt`
oracle.

## Correctness

The scaling corpus produced 1,476 validations. Floating GDA passed all 738 of
its rows; DzmingLi passed 630 and failed 108. Failures start at 4,096 coefficient
digits for add, subtract, multiply, and divide. Compare remains correct through
20,000 digits.

The official GDA audit executes 17,651 legal rows from 23 arithmetic/base files;
floating GDA passes all of them. DzmingLi passes every shared arithmetic
operation, comparison, and `apply`, but fails 329 `toSci` rows
because formatting does not apply active precision and rounding. Official
finite operands reach only 64 coefficient digits, so decTest cannot replace
the large-coefficient oracle.

The scalable layer covers 19 exact operations. The 14 newly added operations
run through 1,024 digits; `exp`, `ln`, and `log10` remain decTest-only because
identity-only timing would not measure their algorithms and general results
need a separate independent transcendental oracle.

DzmingLi's `digit_count` evaluates `bit_length * 30103` in signed `Int`. On the
current native target it can overflow near 21,475 coefficient digits. Product,
square, FMA, and integer-power results may double coefficient length and cross
the boundary from inputs near 10,738 digits. Multiplication completes at 10,000
digits and non-product operations at 20,000; 32,768 and 65,536 digits reproduce
the abort. These are analytical and observed bounds, not one universal exact
first-failure point.

## Performance

DzmingLi leads at 1–64 digits. At 256 digits, all five tested operations switch
to floating GDA in both timing scopes. At 1,024 digits, where both remain
correct, floating GDA is approximately `3.4–33.8×` faster depending on operation
and scope. At invalid larger arithmetic sizes, reports retain validated GDA
latency but omit paired speedup decisions.

## Limits

Results are from one Apple M4 native release run with uncontrolled CPU
frequency. The corpus has three deterministic scale profiles and division uses
small terminating divisors. These results are regression evidence, not a
universal implementation ranking.

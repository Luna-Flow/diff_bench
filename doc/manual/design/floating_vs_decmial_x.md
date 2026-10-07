# `floating_vs_decmial_x` design and performance report

## Goal

The package compares the correctness and performance of `moonbitlang/x/decimal@0.4.46` and `Luna-Flow/floating/decimal_gda@0.7.1` on identical neutral inputs. Fixture construction, type conversion, validation and result normalization all stay outside the timed region.

This report describes only the results for the current repository and the current environment. It does not speak for all hardware, compilers or decimal implementations.

## Semantic groups

- `exact_overlap`: operations whose mathematical result both APIs can represent directly.
- `x_compatible`: multiplication and division follow X's policy of 28 fractional digits with truncation toward zero; GDA performs the matching post-processing inside the timed path.

The two groups must not be read together; in particular, GDA's complete semantic pipeline and a single X arithmetic call are not the same kind of cost.

## Summary of results

### Addition and subtraction

GDA leads at 1–256 digits (`0.23–0.39 µs/op`, against `0.46–0.66 µs/op` for X); X overtakes it at 1,024–4,096 digits and is about `1.4–1.8×` faster at the upper end. Both grow roughly linearly; the difference comes mainly from small-object paths, scale alignment and the constant overhead of big integers.

### Multiplication

X leads at every tested size by about `2.1–2.7×`. The curves have similar shapes, so the difference is mainly a constant factor and does not support a claim that the complexity classes differ.

### Division

Under `exact_overlap`, GDA is about `1.2–4.1×` faster at 1–64 digits and X is about `1.3–3.4×` faster at 256–4,096 digits. In the `x_compatible` pipeline the two stay within about `1.2×` of each other up to 256 digits, and GDA is about `1.8×` faster at 1,024 digits and `3.8×` faster at 4,096 digits. Division is the operation most affected by working precision, rounding policy and the internal division algorithm, so it cannot be compared apart from its semantics.

### Comparison

GDA is faster at every tested size, from about `3.4×` at 1 digit to about `14.8×` at 4,096 digits. This matches the implementation paths: GDA can compare by sign, coefficient length and adjusted exponent, while X has to align the operands to a common scale.

## Relation to other implementations

- Fixed-precision `decimal64/decimal128` is usually faster within its precision bound, because it never needs unbounded big integers.
- In arbitrary-precision BigInt decimal libraries, addition and subtraction are usually close to `O(n)`; multiplication and division depend on the underlying big-integer algorithms and their thresholds.
- Mature C implementations usually benefit from limb arithmetic, memory layout and compiler or assembly optimizations, so the numbers of this benchmark cannot be extrapolated to them.
- IEEE/GDA-style libraries usually pay extra for general capabilities such as precision contexts, rounding modes, status flags, NaN and Infinity.

## Conclusion and boundaries

For this workload, X suits simple, fixed, high-performance decimal arithmetic, and GDA suits scenarios that need complete GDA/IEEE semantics. The conclusion serves only as an implementation reference and for regression analysis in this repository; it is not a general recommendation for choosing a library.

## Publication policy

`floating_vs_decmial_x` is a benchmark and reference package that stays in the GitHub repository. It is not published to Mooncakes and makes no promise to be a stable dependency or runtime API for downstream projects.

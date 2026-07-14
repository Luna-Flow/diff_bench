# Design and Performance Report

The benchmark compares `moonbitlang/x/decimal@0.4.46` with `Luna-Flow/floating/decimal_gda@0.6.1` on shared neutral fixtures; setup, validation, conversion, and normalization are outside timing. `exact_overlap` measures directly shared mathematical semantics. `x_compatible` also measures X's 28-fractional-digit, truncation-toward-zero pipeline.

Observed results: GDA is usually slightly faster for addition/subtraction at 1–256 digits, but X is faster at 4096 digits; X leads multiplication by roughly `2.6–3.9×`; GDA division is about `1.1–1.4×` slower for `exact_overlap` and `1.4–6.5×` slower for `x_compatible`; GDA comparison is about `1.1–1.5×` faster at common sizes and about `5×` faster at 4096 digits. These are workload- and host-specific observations, not universal library claims.

Compared with other implementations, fixed-precision decimal64/128 often wins within its bound, arbitrary-precision costs depend on BigInt algorithms, optimized C implementations benefit from low-level tuning, and full IEEE/GDA contexts add semantic overhead. This package remains a GitHub-only reference benchmark and is not published to Mooncakes.

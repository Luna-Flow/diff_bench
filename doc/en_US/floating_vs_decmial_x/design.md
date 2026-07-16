# Design and Performance Report

The current benchmark compares `moonbitlang/x/decimal@0.4.46` with `Luna-Flow/floating/decimal_gda@0.7.1` on shared neutral fixtures; setup, validation, conversion, and normalization are outside timing. `exact_overlap` measures directly shared mathematical semantics. `x_compatible` also measures X's 28-fractional-digit, truncation-toward-zero pipeline.

Observed results: GDA leads addition/subtraction at 1–256 digits, while X leads at 1,024–4,096 digits; X leads multiplication by roughly `2.1–2.7×`; division changes from a GDA advantage at small exact-overlap inputs to an X advantage at larger ones, while the X-compatible pipeline stays near parity through 256 digits and favors GDA at larger sizes; GDA comparison is about `3.4–14.8×` faster. These are workload- and host-specific observations, not universal library claims.

Compared with other implementations, fixed-precision decimal64/128 often wins within its bound, arbitrary-precision costs depend on BigInt algorithms, optimized C implementations benefit from low-level tuning, and full IEEE/GDA contexts add semantic overhead. This package remains a GitHub-only reference benchmark and is not published to Mooncakes.

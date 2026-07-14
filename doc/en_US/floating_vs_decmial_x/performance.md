# Multilingual Performance Analysis

## Measurement Contract

This report covers the MoonBit native release benchmark for `moonbitlang/x/decimal@0.4.46` and `Luna-Flow/floating/decimal_gda@0.6.1`. Fixture construction, parsing, conversion, correctness checks, and formatting are outside the timed region. `exact_overlap` measures shared mathematical semantics; `x_compatible` also includes 28 fractional digits and truncation toward zero.

## Results

- **Add/subtract:** GDA is usually slightly faster at 1–256 digits (`0.6–1.1 µs/op`); at 4096 digits X is `4.4–4.6 µs/op` versus GDA `7.7–8.1 µs/op`. Growth is broadly linear.
- **Multiply:** X leads at every size: about `3.9×` for tiny inputs, `2.75×` at 8–28 digits, and `2.6×` at 4096 digits. This indicates a constant-factor advantage, not a proven complexity difference.
- **Divide:** GDA is about `1.1–1.4×` slower for `exact_overlap` and `1.4–6.5×` slower for `x_compatible`, where semantic post-processing is timed.
- **Compare:** GDA is about `1.1–1.5×` faster at common sizes and about `5×` faster at 4096 digits, consistent with sign/coefficient-length/exponent shortcuts that avoid some scale alignment.

## Cross-Implementation Context

Fixed-precision decimal64/128 is often fastest within its bound. Arbitrary-precision add/subtract is commonly near `O(n)`, while multiply/divide depend on BigInt algorithms and thresholds. Mature C implementations may benefit from limb layout and SIMD/assembly. Full IEEE/GDA contexts pay for rounding, status flags, and special values.

## Conclusion and Limits

For this workload, X favors simple high-throughput arithmetic; GDA favors explicit precision, rounding, and context semantics. The observed ratio is broadly stable with size, supporting a constant-factor implementation gap rather than a different asymptotic class; larger BigInt sizes may expose thresholds. Other GDA implementations may have similar overhead with similar algorithms, but limb layout, caching, native code, fixed precision, or hardware can change constants; the standard does not prescribe an algorithm. Results are specific to these fixtures, target, build mode, and host. Recheck JSONL and `artifacts/` reports. This benchmark remains GitHub-only and is not published to Mooncakes.

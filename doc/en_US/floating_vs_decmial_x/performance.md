# Multilingual Performance Analysis

## Measurement Contract

This report covers the current MoonBit native release benchmark comparing `moonbitlang/x/decimal@0.4.46` and `Luna-Flow/floating/decimal_gda@0.7.1`. Fixture construction, parsing, conversion, correctness checks, and formatting are outside the timed region. `exact_overlap` measures shared mathematical semantics; `x_compatible` also includes 28 fractional digits and truncation toward zero.

## Results

- **Add/subtract:** GDA leads at 1–256 digits (`0.23–0.39 µs/op` versus X's `0.46–0.66 µs/op`); X leads at 1,024–4,096 digits and is about `1.4–1.8×` faster at the upper end.
- **Multiply:** X leads at every scaling point by about `2.1–2.7×`, a constant-factor advantage in this workload rather than evidence of a different complexity class.
- **Divide:** For `exact_overlap`, GDA leads by `1.2–4.1×` at 1–64 digits, while X leads by `1.3–3.4×` at 256–4,096 digits. In `x_compatible`, the two implementations stay within about `1.2×` through 256 digits, then GDA leads by about `1.8×` at 1,024 and `3.8×` at 4,096 digits.
- **Compare:** GDA leads at every scaling point, from about `3.4×` at 1 digit to `14.8×` at 4,096 digits, consistent with early sign/coefficient-length/exponent shortcuts.

## Cross-Implementation Context

Fixed-precision decimal64/128 is often fastest within its bound. Arbitrary-precision add/subtract is commonly near `O(n)`, while multiply/divide depend on BigInt algorithms and thresholds. Mature C implementations may benefit from limb layout and SIMD/assembly. Full IEEE/GDA contexts pay for rounding, status flags, and special values.

## Conclusion and Limits

For this workload, X favors simple high-throughput arithmetic; GDA favors explicit precision, rounding, and context semantics. The observed ratio is broadly stable with size, supporting a constant-factor implementation gap rather than a different asymptotic class; larger BigInt sizes may expose thresholds. Other GDA implementations may have similar overhead with similar algorithms, but limb layout, caching, native code, fixed precision, or hardware can change constants; the standard does not prescribe an algorithm. Results are specific to these fixtures, target, build mode, and host. Recheck JSONL and `artifacts/` reports. This benchmark remains GitHub-only and is not published to Mooncakes.

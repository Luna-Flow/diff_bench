# floating_vs_decmial_x performance

## Measurement contract

This report covers a MoonBit native release run comparing `moonbitlang/x/decimal@0.4.46` and `Luna-Flow/floating/decimal_gda@0.7.1`, taken before the MoonBit 0.10 migration. The module now depends on `moonbitlang/x@0.5.5`; the run has not been repeated with it. Fixture construction, parsing, conversion, correctness checks, and formatting are outside the timed region. `exact_overlap` measures shared mathematical semantics; `x_compatible` also includes 28 fractional digits and truncation toward zero.

## Results

- **Add/subtract:** GDA leads at 1–256 digits (`0.23–0.39 µs/op` versus X's `0.46–0.66 µs/op`); X leads at 1,024–4,096 digits and is about `1.4–1.8×` faster at the upper end.
- **Multiply:** For `exact_overlap`, X leads at every scaling point by about `2.1–2.7×`, a constant-factor advantage in this workload rather than evidence of a different complexity class. For `x_compatible`, where both sides also truncate to 28 fractional digits, GDA leads by about `1.8–2.1×` at 1–64 digits, the two are equivalent at 256 digits, and X leads by about `1.9–2.3×` at 1,024–4,096 digits.
- **Divide:** For `exact_overlap`, GDA leads by `1.2–4.1×` at 1–64 digits, while X leads by `1.3–3.4×` at 256–4,096 digits. In `x_compatible`, the two implementations stay within about `1.2×` through 256 digits, then GDA leads by about `1.8×` at 1,024 and `3.8×` at 4,096 digits.
- **Divide caveat:** from 64 digits on, the `x_compatible` fixtures round the GDA operands to the division precision (at most 51 digits) while X divides the full operands, so these GDA timings measure less work; see the [known limitation](../design/floating_vs_decmial_x.md#known-limitation-operand-rounding-in-x-compatible-division). The 1–16-digit points and the whole common-digit run are not affected.
- **Compare:** GDA leads at every scaling point, from about `3.4×` at 1 digit to `14.8×` at 4,096 digits, consistent with early sign/coefficient-length/exponent shortcuts.

## Cross-implementation context

Fixed-precision decimal64/128 is often fastest within its bound. Arbitrary-precision add/subtract is commonly near `O(n)`, while multiply/divide depend on BigInt algorithms and thresholds. Mature C implementations may benefit from limb layout and SIMD/assembly. Full IEEE/GDA contexts pay for rounding, status flags, and special values.

## Conclusion and limits

For this workload, X favors simple high-throughput arithmetic; GDA favors explicit precision, rounding, and context semantics. Only `exact_overlap` multiplication keeps a roughly constant ratio across sizes, which points to a constant-factor gap there. Add, subtract, `exact_overlap` divide and `x_compatible` multiply cross over from GDA to X as the digits grow, and compare moves from about `3.4×` to `14.8×` in GDA's favour, so for those operations the two libraries have different fixed and per-digit costs rather than a constant ratio; larger BigInt sizes may expose further thresholds. Other GDA implementations may have similar overhead with similar algorithms, but limb layout, caching, native code, fixed precision, or hardware can change constants; the standard does not prescribe an algorithm. Neighbouring sizes average over different scale pairs, because the scale profile rotates with the global dataset id (see the [scaling executable design](../design/floating_vs_decmial_x/bench.md)), so a single step of a curve mixes size and scale effects. Results are specific to these fixtures, target, build mode, and host. Recheck JSONL and `artifacts/` reports. This benchmark remains GitHub-only and is not published to Mooncakes.

## Data and figures

The figures and reports for this analysis are kept in the repository: the
[main figure](../../../artifacts/floating_vs_decmial_x/main.svg), the
[scaling report](../../../artifacts/floating_vs_decmial_x/scaling.html) and the
[common-digit report](../../../artifacts/floating_vs_decmial_x/common_digits.html),
with the JSONL records and the Plot IR beside them.

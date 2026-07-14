# Performance Analysis

The expanded common-digit run contains 1,368/1,368 successful validations for
19 operations. The scaling run contains 1,476 validations and runs the 14 new
scalable operations through 1,024 digits.

The scaling run crosses over between 64 and 256 digits. At 1,024 digits,
floating GDA records `0.383–17.586 µs/op` for the original arithmetic-only
operations versus DzmingLi's `12.351–80.126 µs/op`; full-path medians are
`26.835–61.180 µs/op` versus `156.160–209.601 µs/op`.

DzmingLi arithmetic is incorrect from 4,096 digits, so those points are not
speedups. At 20,000 digits the validated GDA medians are `17.037 µs` add,
`19.084 µs` subtract, `74.468 µs` divide, and `0.380 µs` compare for
arithmetic-only; full-path medians are `854.378`, `916.372`, `528.483`, and
`881.238 µs`, respectively.

DzmingLi's arithmetic-only comparison curve jumps sharply at large input sizes:
the medians at 4,096, 8,192, 10,000, 16,384, and 20,000 digits are `110.370`,
`0.103`, `723.515`, `0.100`, and `2,377.639 µs/op`, respectively. This is not
ordinary measurement noise. Comparison has data-dependent short-circuit paths:
some fixtures can be ordered immediately from metadata such as sign, exponent,
or significant-digit count, while others require a deep coefficient comparison.
Connecting those two execution classes produces the spikes, which must not be
interpreted as instability caused by digit count alone. Full-path timing also
includes parsing and construction costs that grow with input size, so the jumps
are much less visible there. Comparison performance should be evaluated in
separate input classes such as early mismatch, late mismatch, and equal values.

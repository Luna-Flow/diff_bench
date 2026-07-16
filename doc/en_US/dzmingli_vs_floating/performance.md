# Performance Analysis

The current `0.7.1` run contains 1,476 scaling validations, with 1,368 passes
and 108 DzmingLi failures. The expanded common-digit run contains 1,368/1,368
successful validations for 19 operations.

At 1,024 digits, where both implementations still pass the oracle, floating
GDA records `0.978–16.798 µs/op` for the five arithmetic-only operations versus
DzmingLi's `12.459–78.978 µs/op`. Full-path medians are `7.427–24.133 µs/op`
versus `152.145–205.549 µs/op`. The resulting GDA speedup ranges from `3.54×`
for arithmetic-only multiplication to `95.44×` for arithmetic-only comparison.

DzmingLi arithmetic is incorrect from 4,096 digits, so those points are not
speedups. At 20,000 digits the validated GDA medians are `14.810 µs` add,
`15.083 µs` subtract, `60.588 µs` divide, and `0.130 µs` compare for
arithmetic-only; full-path medians are `154.468`, `155.582`, `131.363`, and
`139.865 µs`, respectively.

DzmingLi's arithmetic-only comparison curve remains data-dependent at large
input sizes: its medians at 4,096, 8,192, 10,000, 16,384, and 20,000 digits
are `105.918`, `0.103`, `675.705`, `0.101`, and `2,203.063 µs/op`. Some fixtures
can be ordered immediately from sign, exponent, or significant-digit metadata,
while others require a deep coefficient comparison. The connected curve
therefore contains execution-class spikes rather than a single digit-count
scaling law. Full-path timing also includes parsing and construction costs;
comparison should be evaluated by input class as well as coefficient size.

///|
pub fn default_suite() -> Suite {
  {
    name: "decimal-x-floating-gda",
    operations: [Add, Subtract, Multiply, Divide, Compare, Parse, Format],
    scales: [0, 2, 6, 18, 28],
    timing_scope: OperationOnly,
    warmup: 5,
    samples: 20,
  }
}

///|
pub fn suite_case_count(suite : Suite, per_operation : Int) -> Int {
  suite.operations.length() * suite.scales.length() * per_operation
}

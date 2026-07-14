///|
pub fn default_suite() -> Suite {
  {
    name: "dzmingli-vs-floating-gda",
    operations: [
      Add,
      Subtract,
      Multiply,
      Divide,
      DivideInteger,
      Remainder,
      Power,
      Fma,
      SquareRoot,
      Plus,
      Minus,
      Abs,
      Quantize,
      Rescale,
      ScaleB,
      Reduce,
      ToIntegralExact,
      ToIntegralValue,
      Compare,
      Parse,
      Format,
    ],
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

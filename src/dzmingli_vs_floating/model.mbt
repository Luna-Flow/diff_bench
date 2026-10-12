///|
/// A signed decimal value represented without a binary floating-point step.
pub(all) struct DecimalValue {
  coefficient : @bigint.BigInt
  scale : Int32
}

///|
/// The operation families exercised by this benchmark.
pub(all) enum Operation {
  Add
  Subtract
  Multiply
  Divide
  DivideInteger
  Remainder
  Power
  Fma
  SquareRoot
  Plus
  Minus
  Abs
  Quantize
  Rescale
  ScaleB
  Reduce
  ToIntegralExact
  ToIntegralValue
  Compare
  Parse
  Format
}

///|
/// Input distribution used by a generated case.
pub(all) enum OperandShape {
  Small
  Large
  Boundary
  Cancellation
  Repeating
}

///|
/// Which part of a run is included in a timing sample.
pub(all) enum TimingScope {
  OperationOnly
  FullPath
}

///|
/// A deterministic benchmark case. The strings are also the serialization boundary.
pub struct BenchmarkCase {
  id : String
  operation : Operation
  shape : OperandShape
  left : String
  right : String
  scale : Int32
}

///|
/// Stable metadata for a benchmark suite.
pub struct Suite {
  name : String
  operations : Array[Operation]
  scales : Array[Int32]
  timing_scope : TimingScope
  warmup : Int32
  samples : Int32
}

///|
/// A normalized, comparable result.
pub struct OracleResult {
  value : DecimalValue
  canonical : String
}

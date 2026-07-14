///|
/// A signed decimal value represented without a binary floating-point step.
pub(all) struct DecimalValue {
  coefficient : @bigint.BigInt
  scale : Int
}

///|
/// The operation families exercised by this benchmark.
pub(all) enum Operation {
  Add
  Subtract
  Multiply
  Divide
  Compare
  Parse
  Format
}

///|
/// The semantic contract shared by both implementations during a benchmark.
pub(all) enum DecimalSemantics {
  ExactOverlap
  XCompatible
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
  ConstructionAndOperation
  OperationOnly
}

///|
/// A deterministic benchmark case. The strings are also the serialization boundary.
pub struct BenchmarkCase {
  id : String
  operation : Operation
  shape : OperandShape
  left : String
  right : String
  scale : Int
}

///|
/// Stable metadata for a benchmark suite.
pub struct Suite {
  name : String
  operations : Array[Operation]
  scales : Array[Int]
  timing_scope : TimingScope
  warmup : Int
  samples : Int
}

///|
/// A normalized, comparable result.
pub struct OracleResult {
  value : DecimalValue
  canonical : String
}

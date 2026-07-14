///|
pub fn operation_name(operation : Operation) -> String {
  match operation {
    Add => "add"
    Subtract => "subtract"
    Multiply => "multiply"
    Divide => "divide"
    Compare => "compare"
    Parse => "parse"
    Format => "format"
  }
}

///|
fn shape_name(shape : OperandShape) -> String {
  match shape {
    Small => "small"
    Large => "large"
    Boundary => "boundary"
    Cancellation => "cancellation"
    Repeating => "repeating"
  }
}

///|
/// Stable serialization used as the sole input to Mare Mark fingerprinting.
pub fn serialize_case(case : BenchmarkCase) -> String {
  [
    "decimal-neutral-v1",
    case.id,
    operation_name(case.operation),
    shape_name(case.shape),
    case.left,
    case.right,
    case.scale.to_string(),
  ].join("\n")
}

///|
pub fn fingerprint_case(case : BenchmarkCase) -> String {
  @mare_generator.stable_fingerprint(serialize_case(case))
}

///|
fn digit_for(seed : Int, index : Int) -> Char {
  let digit = ((seed + index * 7) % 9 + 9) % 9
  ('1'.to_int() + digit).unsafe_to_char()
}

///|
/// Creates a decimal string with deterministic digits and optional sign.
pub fn generate_decimal(
  seed : Int,
  digits : Int,
  scale : Int,
  negative : Bool,
) -> String {
  if digits <= 0 {
    abort("digits must be positive")
  }
  if scale < 0 {
    abort("scale must be non-negative")
  }
  let builder = StringBuilder(size_hint=digits)
  for index in 0..<digits {
    builder.write_char(digit_for(seed, index))
  }
  let raw = builder.to_string()
  let body = if scale == 0 {
    raw
  } else if digits > scale {
    (raw[:digits - scale] + "." + raw[digits - scale:]).to_owned()
  } else {
    "0." + "0".repeat(scale - digits) + raw
  }
  if negative {
    "-" + body
  } else {
    body
  }
}

///|
/// Produces a deterministic case matrix without consulting wall-clock time or RNG state.
pub fn generate_cases(
  seed : Int,
  count : Int,
  operation : Operation,
) -> Array[BenchmarkCase] {
  let cases = []
  for index in 0..<count {
    let digits = 1 + (seed + index * 11) % 24
    let scale = (seed + index * 5) % 9
    let shape = match index % 5 {
      0 => Small
      1 => Large
      2 => Boundary
      3 => Cancellation
      _ => Repeating
    }
    cases.push({
      id: "case-" + index.to_string(),
      operation,
      shape,
      left: generate_decimal(seed + index, digits, scale, index % 2 == 1),
      right: generate_decimal(seed + index * 3, digits, scale, index % 3 == 0),
      scale,
    })
  }
  cases
}

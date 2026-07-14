///|
fn pow10(n : Int) -> @bigint.BigInt {
  let mut result = 1N
  for _ in 0..<n {
    result = result * 10N
  }
  result
}

///|
fn abs_bigint(value : @bigint.BigInt) -> @bigint.BigInt {
  if value < 0N {
    -value
  } else {
    value
  }
}

///|
/// Removes trailing decimal zeros while preserving the represented value.
pub fn normalize(value : DecimalValue) -> DecimalValue {
  if value.coefficient.is_zero() {
    return { coefficient: 0N, scale: 0 }
  }
  let mut coefficient = value.coefficient
  let mut scale = value.scale
  while scale > 0 && (coefficient % 10N).is_zero() {
    coefficient = coefficient / 10N
    scale = scale - 1
  }
  { coefficient, scale }
}

///|
/// Converts a value to a canonical decimal string (no exponent notation).
pub fn canonical_string(value : DecimalValue) -> String {
  let normalized = normalize(value)
  let coefficient = normalized.coefficient
  let negative = coefficient < 0N
  let digits = abs_bigint(coefficient).to_string()
  let scale = normalized.scale
  if scale == 0 {
    if negative {
      "-" + digits
    } else {
      digits
    }
  } else {
    let length = digits.length()
    let body = if length > scale {
      digits[:length - scale] + "." + digits[length - scale:]
    } else {
      "0." + "0".repeat(scale - length) + digits
    }
    let body = body.to_owned()
    if negative {
      "-" + body
    } else {
      body
    }
  }
}

///|
pub fn to_oracle_result(value : DecimalValue) -> OracleResult {
  let normalized = normalize(value)
  { value: normalized, canonical: canonical_string(normalized) }
}

///|
fn rescale(value : DecimalValue, target_scale : Int) -> DecimalValue {
  if value.scale == target_scale {
    value
  } else if value.scale < target_scale {
    {
      coefficient: value.coefficient * pow10(target_scale - value.scale),
      scale: target_scale,
    }
  } else {
    {
      coefficient: value.coefficient / pow10(value.scale - target_scale),
      scale: target_scale,
    }
  }
}

///|
fn aligned(
  left : DecimalValue,
  right : DecimalValue,
) -> (DecimalValue, DecimalValue) {
  let scale = if left.scale > right.scale { left.scale } else { right.scale }
  (rescale(left, scale), rescale(right, scale))
}

///|
pub fn add(left : DecimalValue, right : DecimalValue) -> DecimalValue {
  let (left, right) = aligned(left, right)
  normalize({
    coefficient: left.coefficient + right.coefficient,
    scale: left.scale,
  })
}

///|
pub fn subtract(left : DecimalValue, right : DecimalValue) -> DecimalValue {
  let (left, right) = aligned(left, right)
  normalize({
    coefficient: left.coefficient - right.coefficient,
    scale: left.scale,
  })
}

///|
pub fn multiply(left : DecimalValue, right : DecimalValue) -> DecimalValue {
  normalize({
    coefficient: left.coefficient * right.coefficient,
    scale: left.scale + right.scale,
  })
}

///|
pub fn compare(left : DecimalValue, right : DecimalValue) -> Int {
  let (left, right) = aligned(left, right)
  normalize_order(left.coefficient.compare(right.coefficient))
}

///|
fn normalize_order(order : Int) -> Int {
  if order < 0 {
    -1
  } else if order > 0 {
    1
  } else {
    0
  }
}

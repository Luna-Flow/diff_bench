///|
/// Computes the exact finite product.
pub fn oracle_multiply(
  left : DecimalValue,
  right : DecimalValue,
) -> DecimalValue {
  multiply(left, right)
}

///|
fn gcd(left : @bigint.BigInt, right : @bigint.BigInt) -> @bigint.BigInt {
  let mut left = abs_bigint(left)
  let mut right = abs_bigint(right)
  while !right.is_zero() {
    let remainder = left % right
    left = right
    right = remainder
  }
  left
}

///|
/// Computes an exact finite quotient and rejects repeating decimals.
pub fn oracle_divide(left : DecimalValue, right : DecimalValue) -> DecimalValue {
  if right.coefficient.is_zero() {
    abort("division by zero in decimal oracle")
  }
  let mut numerator = left.coefficient * pow10(right.scale)
  let mut denominator = right.coefficient * pow10(left.scale)
  if denominator < 0N {
    numerator = -numerator
    denominator = -denominator
  }
  let divisor = gcd(numerator, denominator)
  numerator = numerator / divisor
  denominator = denominator / divisor
  let mut finite_denominator = denominator
  while (finite_denominator % 2N).is_zero() {
    finite_denominator = finite_denominator / 2N
  }
  while (finite_denominator % 5N).is_zero() {
    finite_denominator = finite_denominator / 5N
  }
  if finite_denominator != 1N {
    abort("repeating decimal in exact decimal oracle")
  }
  let mut scale = 0
  while !(numerator % denominator).is_zero() {
    numerator = numerator * 10N
    scale = scale + 1
  }
  normalize({ coefficient: numerator / denominator, scale })
}

///|
fn oracle_divide_integer(
  left : DecimalValue,
  right : DecimalValue,
) -> DecimalValue {
  if right.coefficient.is_zero() {
    abort("division by zero in decimal oracle")
  }
  {
    coefficient: left.coefficient *
    pow10(right.scale) /
    (right.coefficient * pow10(left.scale)),
    scale: 0,
  }
}

///|
fn oracle_power(left : DecimalValue, right : DecimalValue) -> DecimalValue {
  if right.scale != 0 || right.coefficient < 0N {
    abort("power oracle requires a non-negative integer exponent")
  }
  let exponent = right.coefficient.to_int()
  let mut result : DecimalValue = { coefficient: 1N, scale: 0 }
  for _ in 0..<exponent {
    result = multiply(result, left)
  }
  result
}

///|
fn integer_square_root(value : @bigint.BigInt) -> @bigint.BigInt {
  if value < 0N {
    abort("square root oracle requires a non-negative value")
  }
  if value < 2N {
    return value
  }
  let mut estimate = 1N
  let digits = value.to_string().length()
  for _ in 0..<((digits + 1) / 2) {
    estimate = estimate * 10N
  }
  let mut next = (estimate + value / estimate) / 2N
  while next < estimate {
    estimate = next
    next = (estimate + value / estimate) / 2N
  }
  if estimate * estimate != value {
    abort("square root oracle input is not a perfect square")
  }
  estimate
}

///|
fn oracle_square_root(value : DecimalValue) -> DecimalValue {
  if value.scale % 2 != 0 {
    abort("square root oracle requires an even scale")
  }
  normalize({
    coefficient: integer_square_root(value.coefficient),
    scale: value.scale / 2,
  })
}

///|
fn oracle_quantize(
  value : DecimalValue,
  quantum : DecimalValue,
) -> DecimalValue {
  rescale(value, quantum.scale)
}

///|
fn oracle_rescale(value : DecimalValue, scale : DecimalValue) -> DecimalValue {
  if scale.scale != 0 {
    abort("rescale oracle requires an integer scale operand")
  }
  let target_exponent = scale.coefficient.to_int()
  rescale(value, -target_exponent)
}

///|
fn oracle_scaleb(value : DecimalValue, scale : DecimalValue) -> DecimalValue {
  if scale.scale != 0 {
    abort("scaleb oracle requires an integer scale operand")
  }
  let adjusted_scale = value.scale - scale.coefficient.to_int()
  if adjusted_scale < 0 {
    normalize({
      coefficient: value.coefficient * pow10(-adjusted_scale),
      scale: 0,
    })
  } else {
    normalize({ coefficient: value.coefficient, scale: adjusted_scale })
  }
}

///|
pub fn oracle_operation3(
  operation : Operation,
  left : DecimalValue,
  right : DecimalValue,
  third : DecimalValue,
) -> OracleResult {
  let value = match operation {
    Add => add(left, right)
    Subtract => subtract(left, right)
    Multiply => oracle_multiply(left, right)
    Divide => oracle_divide(left, right)
    DivideInteger => oracle_divide_integer(left, right)
    Remainder =>
      subtract(left, multiply(oracle_divide_integer(left, right), right))
    Power => oracle_power(left, right)
    Fma => add(multiply(left, right), third)
    SquareRoot => oracle_square_root(left)
    Plus => left
    Minus => { coefficient: -left.coefficient, scale: left.scale }
    Abs => { coefficient: abs_bigint(left.coefficient), scale: left.scale }
    Quantize => oracle_quantize(left, right)
    Rescale => oracle_rescale(left, right)
    ScaleB => oracle_scaleb(left, right)
    Reduce => normalize(left)
    ToIntegralExact | ToIntegralValue => rescale(left, 0)
    Compare =>
      { coefficient: @bigint.BigInt::from_int(compare(left, right)), scale: 0 }
    Parse => left
    Format => left
  }
  to_oracle_result(value)
}

///|
pub fn oracle_operation(
  operation : Operation,
  left : DecimalValue,
  right : DecimalValue,
) -> OracleResult {
  oracle_operation3(operation, left, right, { coefficient: 0N, scale: 0 })
}

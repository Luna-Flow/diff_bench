///|
/// The Mare Mark-compatible product oracle: 28 fractional digits, truncation toward zero.
pub fn oracle_multiply(
  left : DecimalValue,
  right : DecimalValue,
) -> DecimalValue {
  let product = multiply(left, right)
  if product.scale <= 28 {
    product
  } else {
    normalize({
      coefficient: product.coefficient / pow10(product.scale - 28),
      scale: 28,
    })
  }
}

///|
/// Computes a quotient at the oracle scale, truncating toward zero.
pub fn oracle_divide(left : DecimalValue, right : DecimalValue) -> DecimalValue {
  if right.coefficient.is_zero() {
    abort("division by zero in decimal oracle")
  }
  let numerator_scale = 28 + right.scale - left.scale
  let numerator = if numerator_scale >= 0 {
    left.coefficient * pow10(numerator_scale)
  } else {
    left.coefficient / pow10(-numerator_scale)
  }
  normalize({ coefficient: numerator / right.coefficient, scale: 28 })
}

///|
pub fn oracle_operation(
  operation : Operation,
  left : DecimalValue,
  right : DecimalValue,
) -> OracleResult {
  let value = match operation {
    Add => add(left, right)
    Subtract => subtract(left, right)
    Multiply => oracle_multiply(left, right)
    Divide => oracle_divide(left, right)
    Compare =>
      { coefficient: @bigint.BigInt::from_int(compare(left, right)), scale: 0 }
    Parse => left
    Format => left
  }
  to_oracle_result(value)
}

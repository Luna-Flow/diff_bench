///|
/// Parses a finite decimal string, including scientific notation, into the neutral model.
pub fn parse_decimal_value(source : String) -> DecimalValue {
  let mut coefficient = 0N
  let mut scale = 0
  let mut exponent = 0
  let mut negative = false
  let mut exponent_negative = false
  let mut after_decimal = false
  let mut in_exponent = false
  let mut saw_digit = false
  let mut saw_exponent_digit = false
  let mut index = 0
  for character in source {
    if character == '-' && index == 0 {
      negative = true
    } else if character == '+' && index == 0 {
      ()
    } else if character == '.' && !after_decimal && !in_exponent {
      after_decimal = true
    } else if (character == 'e' || character == 'E') &&
      saw_digit &&
      !in_exponent {
      in_exponent = true
    } else if character == '-' && in_exponent && !saw_exponent_digit {
      exponent_negative = true
    } else if character == '+' && in_exponent && !saw_exponent_digit {
      ()
    } else if character >= '0' && character <= '9' {
      let digit = character.to_int() - '0'.to_int()
      if in_exponent {
        exponent = exponent * 10 + digit
        saw_exponent_digit = true
      } else {
        coefficient = coefficient * 10N + @bigint.BigInt::from_int(digit)
        if after_decimal {
          scale = scale + 1
        }
        saw_digit = true
      }
    } else {
      abort("invalid finite decimal: " + source)
    }
    index = index + 1
  }
  if !saw_digit || (in_exponent && !saw_exponent_digit) {
    abort("invalid finite decimal: " + source)
  }
  if negative {
    coefficient = -coefficient
  }
  let signed_exponent = if exponent_negative { -exponent } else { exponent }
  let adjusted_scale = scale - signed_exponent
  if adjusted_scale < 0 {
    normalize({ coefficient: coefficient * pow10(-adjusted_scale), scale: 0 })
  } else {
    normalize({ coefficient, scale: adjusted_scale })
  }
}

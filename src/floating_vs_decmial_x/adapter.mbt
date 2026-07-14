///|
pub struct DecimalFixture {
  neutral_left : DecimalValue
  neutral_right : DecimalValue
  operation : Operation
  semantics : DecimalSemantics
  x_left : @x_decimal.Decimal
  x_right : @x_decimal.Decimal
  gda_left : @floating_gda.Decimal
  gda_right : @floating_gda.Decimal
  gda_quantum_28 : @floating_gda.Decimal
  gda_context : @floating_gda.GdaContext
}

///|
pub(all) enum DecimalObservation {
  X(@x_decimal.Decimal)
  XCompare(Int)
  Gda(@floating_gda.GdaOutcome[@floating_gda.Decimal])
}

///|
fn decimal_digits(value : @bigint.BigInt) -> Int {
  abs_bigint(value).to_string().length()
}

///|
pub fn working_precision(
  operation : Operation,
  left : DecimalValue,
  right : DecimalValue,
  semantics? : DecimalSemantics = XCompatible,
) -> Int {
  let left_digits = decimal_digits(left.coefficient)
  let right_digits = decimal_digits(right.coefficient)
  match operation {
    Add | Subtract =>
      Int::max(left_digits, right_digits) +
      Int::abs(left.scale - right.scale) +
      2
    Multiply => left_digits + right_digits + 1
    Divide =>
      match semantics {
        ExactOverlap => left_digits + right_digits + 2
        XCompatible => {
          let integer_digits = Int::max(
            1,
            left_digits - left.scale - right_digits + right.scale + 1,
          )
          integer_digits + 30
        }
      }
    Compare | Parse | Format => Int::max(left_digits, right_digits) + 1
  }
}

///|
pub fn x_from_neutral(value : DecimalValue) -> @x_decimal.Decimal {
  match @x_decimal.Decimal::new(value.coefficient, value.scale) {
    Some(decimal) => decimal
    None => abort("x/decimal rejected neutral decimal scale")
  }
}

///|
pub fn gda_from_neutral(
  value : DecimalValue,
  precision : Int,
) -> @floating_gda.Decimal {
  match
    @floating_gda.Decimal::from_string(canonical_string(value), precision~) {
    Some(decimal) => decimal
    None => abort("floating/decimal_gda rejected neutral decimal")
  }
}

///|
pub fn prepare_fixture(
  operation : Operation,
  left : DecimalValue,
  right : DecimalValue,
  semantics? : DecimalSemantics = XCompatible,
) -> DecimalFixture {
  let precision = working_precision(operation, left, right, semantics~)
  {
    neutral_left: left,
    neutral_right: right,
    operation,
    semantics,
    x_left: x_from_neutral(left),
    x_right: x_from_neutral(right),
    gda_left: gda_from_neutral(left, precision),
    gda_right: gda_from_neutral(right, precision),
    gda_quantum_28: gda_from_neutral({ coefficient: 1N, scale: 28 }, precision),
    gda_context: @floating_gda.context(
      precision~,
      rounding=@floating_gda.GdaRoundingMode::Down,
    ),
  }
}

///|
pub fn run_x(fixture : DecimalFixture) -> DecimalObservation {
  match fixture.operation {
    Compare => {
      let order = normalize_order(fixture.x_left.compare(fixture.x_right))
      XCompare(order)
    }
    Parse | Format => X(fixture.x_left)
    Add | Subtract | Multiply | Divide => {
      let value = match fixture.operation {
        Add => fixture.x_left + fixture.x_right
        Subtract => fixture.x_left - fixture.x_right
        Multiply => fixture.x_left * fixture.x_right
        Divide => fixture.x_left / fixture.x_right
        _ => abort("unreachable decimal operation")
      }
      X(value)
    }
  }
}

///|
pub fn run_gda(fixture : DecimalFixture) -> DecimalObservation {
  let outcome = match fixture.operation {
    Add =>
      @floating_gda.add(
        fixture.gda_left,
        fixture.gda_right,
        fixture.gda_context,
      )
    Subtract =>
      @floating_gda.subtract(
        fixture.gda_left,
        fixture.gda_right,
        fixture.gda_context,
      )
    Multiply => {
      let product = @floating_gda.multiply(
        fixture.gda_left,
        fixture.gda_right,
        fixture.gda_context,
      )
      if uses_x_compatible_rounding(fixture.semantics) &&
        fixture.neutral_left.scale + fixture.neutral_right.scale > 28 {
        @floating_gda.quantize(
          product.value(),
          fixture.gda_quantum_28,
          product.next_context(),
        )
      } else {
        product
      }
    }
    Divide => {
      let quotient = @floating_gda.divide(
        fixture.gda_left,
        fixture.gda_right,
        fixture.gda_context,
      )
      if uses_x_compatible_rounding(fixture.semantics) {
        @floating_gda.quantize(
          quotient.value(),
          fixture.gda_quantum_28,
          quotient.next_context(),
        )
      } else {
        quotient
      }
    }
    Compare =>
      @floating_gda.compare(
        fixture.gda_left,
        fixture.gda_right,
        fixture.gda_context,
      )
    Parse | Format =>
      @floating_gda.GdaOutcome::Completed(
        fixture.gda_left,
        fixture.gda_context,
        @floating_gda.GdaFlags::none(),
      )
  }
  Gda(outcome)
}

///|
fn uses_x_compatible_rounding(semantics : DecimalSemantics) -> Bool {
  match semantics {
    XCompatible => true
    ExactOverlap => false
  }
}

///|
pub fn canonical_x(value : @x_decimal.Decimal) -> DecimalValue {
  normalize({ coefficient: value.coefficient(), scale: value.scale() })
}

///|
pub fn canonical_observation(observation : DecimalObservation) -> DecimalValue {
  match observation {
    X(value) => canonical_x(value)
    XCompare(value) =>
      { coefficient: @bigint.BigInt::from_int(value), scale: 0 }
    Gda(outcome) => parse_decimal_value(outcome.value().to_string())
  }
}

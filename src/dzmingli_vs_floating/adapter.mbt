///|
pub struct DecimalFixture {
  left_text : String
  right_text : String
  third_text : String
  operation : Operation
  dz_left : @dz_decimal.Decimal
  dz_right : @dz_decimal.Decimal
  dz_third : @dz_decimal.Decimal
  dz_context : @dz_decimal.Context
  gda_left : @floating_gda.Decimal
  gda_right : @floating_gda.Decimal
  gda_third : @floating_gda.Decimal
  gda_context : @floating_gda.GdaContext
}

///|
pub(all) enum DecimalObservation {
  Dz(@dz_decimal.Decimal)
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
) -> Int {
  let left_digits = decimal_digits(left.coefficient)
  let right_digits = decimal_digits(right.coefficient)
  match operation {
    Add | Subtract =>
      Int::max(left_digits, right_digits) +
      Int::abs(left.scale - right.scale) +
      2
    Multiply | Fma | Power => left_digits + right_digits + 2
    Divide | DivideInteger | Remainder => left_digits + right_digits + 2
    SquareRoot => left_digits + 2
    Plus
    | Minus
    | Abs
    | Quantize
    | Rescale
    | ScaleB
    | Reduce
    | ToIntegralExact
    | ToIntegralValue => left_digits + 2
    Compare | Parse | Format => Int::max(left_digits, right_digits) + 1
  }
}

///|
fn dz_from_text(
  source : String,
  context : @dz_decimal.Context,
) -> @dz_decimal.Decimal {
  let (decimal, flags) = @dz_decimal.Decimal::from_string(source, context)
  if flags.conversion_syntax {
    abort("DzmingLi/decimal rejected neutral decimal")
  }
  decimal
}

///|
pub fn dz_from_neutral(value : DecimalValue) -> @dz_decimal.Decimal {
  dz_from_text(canonical_string(value), @dz_decimal.Context::exact())
}

///|
fn gda_from_text(
  source : String,
  context : @floating_gda.GdaContext,
) -> @floating_gda.Decimal {
  @floating_gda.parse(source, context).value()
}

///|
pub fn gda_from_neutral(
  value : DecimalValue,
  precision : Int,
) -> @floating_gda.Decimal {
  gda_from_text(
    canonical_string(value),
    @floating_gda.context(
      precision~,
      rounding=@floating_gda.GdaRoundingMode::Down,
    ),
  )
}

///|
fn dz_context(precision : Int) -> @dz_decimal.Context {
  @dz_decimal.Context::new(precision~, rounding=@dz_decimal.Rounding::Down)
}

///|
pub fn prepare_fixture(
  operation : Operation,
  left : DecimalValue,
  right : DecimalValue,
) -> DecimalFixture {
  prepare_fixture3(operation, left, right, { coefficient: 0N, scale: 0 })
}

///|
pub fn prepare_fixture3(
  operation : Operation,
  left : DecimalValue,
  right : DecimalValue,
  third : DecimalValue,
) -> DecimalFixture {
  let precision = match operation {
    Power => decimal_digits(left.coefficient) * 2 + 4
    Fma =>
      decimal_digits(left.coefficient) +
      decimal_digits(right.coefficient) +
      decimal_digits(third.coefficient) +
      Int::abs(left.scale + right.scale - third.scale) +
      4
    _ => working_precision(operation, left, right) + 2
  }
  let left_text = canonical_string(left)
  let right_text = canonical_string(right)
  let third_text = canonical_string(third)
  let dz_context = dz_context(precision)
  let gda_context = @floating_gda.context(
    precision~,
    rounding=@floating_gda.GdaRoundingMode::Down,
  )
  {
    left_text,
    right_text,
    third_text,
    operation,
    dz_left: dz_from_text(left_text, dz_context),
    dz_right: dz_from_text(right_text, dz_context),
    dz_third: dz_from_text(third_text, dz_context),
    dz_context,
    gda_left: gda_from_text(left_text, gda_context),
    gda_right: gda_from_text(right_text, gda_context),
    gda_third: gda_from_text(third_text, gda_context),
    gda_context,
  }
}

///|
fn run_dz_with(
  operation : Operation,
  left : @dz_decimal.Decimal,
  right : @dz_decimal.Decimal,
  third : @dz_decimal.Decimal,
  context : @dz_decimal.Context,
) -> DecimalObservation {
  match operation {
    Compare => {
      let (value, _) = @dz_decimal.Decimal::compare(left, right, context)
      Dz(value)
    }
    Parse | Format => Dz(left)
    Add
    | Subtract
    | Multiply
    | Divide
    | DivideInteger
    | Remainder
    | Power
    | Fma
    | SquareRoot
    | Plus
    | Minus
    | Abs
    | Quantize
    | Rescale
    | ScaleB
    | Reduce
    | ToIntegralExact
    | ToIntegralValue => {
      let value = match operation {
        Add => @dz_decimal.Decimal::add(left, right, context).0
        Subtract => @dz_decimal.Decimal::subtract(left, right, context).0
        Multiply => @dz_decimal.Decimal::multiply(left, right, context).0
        Divide => @dz_decimal.Decimal::divide(left, right, context).0
        DivideInteger => @dz_decimal.Decimal::divide_int(left, right, context).0
        Remainder => @dz_decimal.Decimal::remainder(left, right, context).0
        Power => @dz_decimal.Decimal::power(left, right, context).0
        Fma => @dz_decimal.Decimal::fma(left, right, third, context).0
        SquareRoot => @dz_decimal.Decimal::sqrt(left, context).0
        Plus => @dz_decimal.Decimal::plus(left, context).0
        Minus => @dz_decimal.Decimal::minus(left, context).0
        Abs => @dz_decimal.Decimal::abs(left, context).0
        Quantize => @dz_decimal.Decimal::quantize(left, right, context).0
        Rescale => @dz_decimal.Decimal::rescale(left, right, context).0
        ScaleB => @dz_decimal.Decimal::scaleb(left, right, context).0
        Reduce => @dz_decimal.Decimal::reduce(left, context).0
        ToIntegralExact =>
          @dz_decimal.Decimal::to_integral_exact(left, context).0
        ToIntegralValue =>
          @dz_decimal.Decimal::to_integral_value(left, context).0
        _ => abort("unreachable decimal operation")
      }
      Dz(value)
    }
  }
}

///|
fn run_gda_with(
  operation : Operation,
  left : @floating_gda.Decimal,
  right : @floating_gda.Decimal,
  third : @floating_gda.Decimal,
  context : @floating_gda.GdaContext,
) -> DecimalObservation {
  let outcome = match operation {
    Add => @floating_gda.add(left, right, context)
    Subtract => @floating_gda.subtract(left, right, context)
    Multiply => @floating_gda.multiply(left, right, context)
    Divide => @floating_gda.divide(left, right, context)
    DivideInteger => @floating_gda.divide_integer(left, right, context)
    Remainder => @floating_gda.remainder(left, right, context)
    Power => @floating_gda.power(left, right, context)
    Fma => @floating_gda.fma(left, right, third, context)
    SquareRoot => @floating_gda.sqrt(left, context)
    Plus => @floating_gda.plus(left, context)
    Minus => @floating_gda.minus(left, context)
    Abs => @floating_gda.abs(left, context)
    Quantize => @floating_gda.quantize(left, right, context)
    Rescale => @floating_gda.rescale(left, right, context)
    ScaleB => @floating_gda.scaleb(left, right, context)
    Reduce => @floating_gda.reduce(left, context)
    ToIntegralExact => @floating_gda.to_integral_exact(left, context)
    ToIntegralValue => @floating_gda.to_integral_value(left, context)
    Compare => @floating_gda.compare(left, right, context)
    Parse | Format =>
      @floating_gda.GdaOutcome::Completed(
        left,
        context,
        @floating_gda.GdaFlags::none(),
      )
  }
  Gda(outcome)
}

///|
pub fn run_dz(fixture : DecimalFixture) -> DecimalObservation {
  run_dz_with(
    fixture.operation,
    fixture.dz_left,
    fixture.dz_right,
    fixture.dz_third,
    fixture.dz_context,
  )
}

///|
pub fn run_dz_full(fixture : DecimalFixture) -> DecimalObservation {
  run_dz_with(
    fixture.operation,
    dz_from_text(fixture.left_text, fixture.dz_context),
    dz_from_text(fixture.right_text, fixture.dz_context),
    dz_from_text(fixture.third_text, fixture.dz_context),
    fixture.dz_context,
  )
}

///|
pub fn run_gda(fixture : DecimalFixture) -> DecimalObservation {
  run_gda_with(
    fixture.operation,
    fixture.gda_left,
    fixture.gda_right,
    fixture.gda_third,
    fixture.gda_context,
  )
}

///|
pub fn run_gda_full(fixture : DecimalFixture) -> DecimalObservation {
  run_gda_with(
    fixture.operation,
    gda_from_text(fixture.left_text, fixture.gda_context),
    gda_from_text(fixture.right_text, fixture.gda_context),
    gda_from_text(fixture.third_text, fixture.gda_context),
    fixture.gda_context,
  )
}

///|
fn canonical_dz(value : @dz_decimal.Decimal) -> DecimalValue {
  parse_decimal_value(value.to_sci_string())
}

///|
pub fn canonical_observation(observation : DecimalObservation) -> DecimalValue {
  match observation {
    Dz(value) => canonical_dz(value)
    Gda(outcome) => parse_decimal_value(outcome.value().to_string())
  }
}

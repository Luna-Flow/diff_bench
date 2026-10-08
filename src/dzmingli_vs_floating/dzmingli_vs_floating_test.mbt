///|
test "normalization removes trailing zeros" {
  let result = @dzmingli_vs_floating.normalize({
    coefficient: 1234500N,
    scale: 4,
  })
  inspect(result.coefficient.to_string(), content="12345")
  inspect(result.scale, content="2")
}

///|
test "canonical string preserves sign and leading fraction zeros" {
  inspect(
    @dzmingli_vs_floating.canonical_string({ coefficient: -12N, scale: 4, }),
    content="-0.0012",
  )
  inspect(
    @dzmingli_vs_floating.canonical_string({ coefficient: 1200N, scale: 2, }),
    content="12",
  )
}

///|
test "oracle multiplication preserves the exact finite result" {
  let left : @dzmingli_vs_floating.DecimalValue = {
    coefficient: 1N,
    scale: 20,
  }
  let right : @dzmingli_vs_floating.DecimalValue = {
    coefficient: 12345678901234567890123456789N,
    scale: 10,
  }
  inspect(
    @dzmingli_vs_floating.canonical_string(
      @dzmingli_vs_floating.oracle_multiply(left, right),
    ),
    content="0.012345678901234567890123456789",
  )
}

///|
test "oracle division preserves an exact terminating quotient" {
  let result = @dzmingli_vs_floating.oracle_divide(
    { coefficient: 125N, scale: 2, },
    { coefficient: 8N, scale: 0, },
  )
  inspect(@dzmingli_vs_floating.canonical_string(result), content="0.15625")
}

///|
test "generated cases are reproducible" {
  let first = @dzmingli_vs_floating.generate_cases(17, 4, Multiply)
  let second = @dzmingli_vs_floating.generate_cases(17, 4, Multiply)
  inspect(first[0].left, content=second[0].left)
  inspect(first[3].right, content=second[3].right)
}

///|
test "generator places a negative sign before a leading fractional zero" {
  inspect(
    @dzmingli_vs_floating.generate_decimal(0, 2, 4, true),
    content="-0.0018",
  )
}

///|
test "DzmingLi and floating GDA agree for both timing paths" {
  let cases : Array[
    (
      @dzmingli_vs_floating.Operation,
      @dzmingli_vs_floating.DecimalValue,
      @dzmingli_vs_floating.DecimalValue,
    ),
  ] = [
    (Add, { coefficient: 12345N, scale: 2, }, { coefficient: -45N, scale: 1, }),
    (
      Subtract,
      { coefficient: -1200N, scale: 3, },
      { coefficient: 75N, scale: 2, },
    ),
    (
      Multiply,
      { coefficient: 123456789N, scale: 18, },
      { coefficient: 987654321N, scale: 18, },
    ),
    (Divide, { coefficient: 1N, scale: 0, }, { coefficient: 8N, scale: 0, }),
    (
      Compare,
      { coefficient: 100N, scale: 2, },
      { coefficient: 999N, scale: 3, },
    ),
  ]
  for item in cases {
    let (operation, left, right) = item
    let fixture = @dzmingli_vs_floating.prepare_fixture(operation, left, right)
    let dz_arithmetic = @dzmingli_vs_floating.canonical_string(
      @dzmingli_vs_floating.canonical_observation(
        @dzmingli_vs_floating.run_dz(fixture),
      ),
    )
    let gda_arithmetic = @dzmingli_vs_floating.canonical_string(
      @dzmingli_vs_floating.canonical_observation(
        @dzmingli_vs_floating.run_gda(fixture),
      ),
    )
    let dz_full = @dzmingli_vs_floating.canonical_string(
      @dzmingli_vs_floating.canonical_observation(
        @dzmingli_vs_floating.run_dz_full(fixture),
      ),
    )
    let gda_full = @dzmingli_vs_floating.canonical_string(
      @dzmingli_vs_floating.canonical_observation(
        @dzmingli_vs_floating.run_gda_full(fixture),
      ),
    )
    inspect(gda_arithmetic, content=dz_arithmetic)
    inspect(dz_full, content=dz_arithmetic)
    inspect(gda_full, content=dz_arithmetic)
  }
}

///|
test "extended arithmetic overlap agrees with exact oracle" {
  let base : @dzmingli_vs_floating.DecimalValue = {
    coefficient: 144N,
    scale: 0,
  }
  let cases : Array[
    (
      @dzmingli_vs_floating.Operation,
      @dzmingli_vs_floating.DecimalValue,
      @dzmingli_vs_floating.DecimalValue,
      @dzmingli_vs_floating.DecimalValue,
    ),
  ] = [
    (
      DivideInteger,
      base,
      { coefficient: 5N, scale: 0, },
      { coefficient: 0N, scale: 0, },
    ),
    (
      Remainder,
      base,
      { coefficient: 5N, scale: 0, },
      { coefficient: 0N, scale: 0, },
    ),
    (
      Power,
      { coefficient: 12N, scale: 0, },
      { coefficient: 2N, scale: 0, },
      { coefficient: 0N, scale: 0, },
    ),
    (
      Fma,
      { coefficient: 12N, scale: 0, },
      { coefficient: 3N, scale: 0, },
      { coefficient: 4N, scale: 0, },
    ),
    (
      SquareRoot,
      base,
      { coefficient: 0N, scale: 0, },
      { coefficient: 0N, scale: 0, },
    ),
    (Plus, base, { coefficient: 0N, scale: 0, }, { coefficient: 0N, scale: 0, }),
    (
      Minus,
      base,
      { coefficient: 0N, scale: 0, },
      { coefficient: 0N, scale: 0, },
    ),
    (
      Abs,
      { coefficient: -144N, scale: 0, },
      { coefficient: 0N, scale: 0, },
      { coefficient: 0N, scale: 0, },
    ),
    (
      Quantize,
      { coefficient: 144N, scale: 2, },
      { coefficient: 1N, scale: 2, },
      { coefficient: 0N, scale: 0, },
    ),
    (
      Rescale,
      { coefficient: 144N, scale: 2, },
      { coefficient: -2N, scale: 0, },
      { coefficient: 0N, scale: 0, },
    ),
    (
      ScaleB,
      { coefficient: 144N, scale: 2, },
      { coefficient: 0N, scale: 0, },
      { coefficient: 0N, scale: 0, },
    ),
    (
      Reduce,
      { coefficient: 1440N, scale: 1, },
      { coefficient: 0N, scale: 0, },
      { coefficient: 0N, scale: 0, },
    ),
    (
      ToIntegralExact,
      base,
      { coefficient: 0N, scale: 0, },
      { coefficient: 0N, scale: 0, },
    ),
    (
      ToIntegralValue,
      base,
      { coefficient: 0N, scale: 0, },
      { coefficient: 0N, scale: 0, },
    ),
  ]
  for item in cases {
    let (operation, left, right, third) = item
    let fixture = @dzmingli_vs_floating.prepare_fixture3(
      operation, left, right, third,
    )
    let expected = @dzmingli_vs_floating.oracle_operation3(
        operation, left, right, third,
      ).canonical
    inspect(
      @dzmingli_vs_floating.canonical_string(
        @dzmingli_vs_floating.canonical_observation(
          @dzmingli_vs_floating.run_dz(fixture),
        ),
      ),
      content=expected,
    )
    inspect(
      @dzmingli_vs_floating.canonical_string(
        @dzmingli_vs_floating.canonical_observation(
          @dzmingli_vs_floating.run_gda(fixture),
        ),
      ),
      content=expected,
    )
  }
}

///|
test "large comparisons normalize implementation-specific ordering" {
  let left = @dzmingli_vs_floating.parse_decimal_value(
    "318642975318642975318642975318642975.3186429753186429753186429753",
  )
  let right = @dzmingli_vs_floating.parse_decimal_value(
    "1864297531864297531864297531864297531864297531864297531864297531",
  )
  let fixture = @dzmingli_vs_floating.prepare_fixture(Compare, left, right)
  let dz_result = @dzmingli_vs_floating.canonical_string(
    @dzmingli_vs_floating.canonical_observation(
      @dzmingli_vs_floating.run_dz(fixture),
    ),
  )
  let gda_result = @dzmingli_vs_floating.canonical_string(
    @dzmingli_vs_floating.canonical_observation(
      @dzmingli_vs_floating.run_gda(fixture),
    ),
  )
  inspect(dz_result, content="-1")
  inspect(gda_result, content="-1")
}

///|
test "Mare Mark fingerprints are stable" {
  let cases = @dzmingli_vs_floating.generate_cases(42, 2, Add)
  inspect(
    @dzmingli_vs_floating.fingerprint_case(cases[0]),
    content=@dzmingli_vs_floating.fingerprint_case(cases[0]),
  )
  inspect(
    @dzmingli_vs_floating.fingerprint_case(cases[0]) ==
    @dzmingli_vs_floating.fingerprint_case(cases[1]),
    content="false",
  )
}

///|
async test "Mare Mark validates and measures arithmetic-only and full paths" {
  let arithmetic_report = @dzmingli_vs_floating.run_mare_benchmark(
    [Add, Multiply],
    OperationOnly,
    [4, 16],
    @dzmingli_vs_floating.smoke_protocol(),
    42UL,
  )
  let full_path_report = @dzmingli_vs_floating.run_mare_benchmark(
    [Add, Multiply],
    FullPath,
    [4, 16],
    @dzmingli_vs_floating.smoke_protocol(),
    42UL,
  )
  inspect(arithmetic_report.failed_count, content="0")
  inspect(full_path_report.failed_count, content="0")
  inspect(arithmetic_report.validation_count, content="8")
  inspect(full_path_report.validation_count, content="8")
  inspect(arithmetic_report.results.length(), content="4")
  inspect(full_path_report.results.length(), content="4")
  inspect(arithmetic_report.results[0].samples, content="3")
  inspect(
    arithmetic_report.results[0]
    .to_json()
    .contains("\"artifact_version\":\"mmka_1\""),
    content="true",
  )
  inspect(
    @dzmingli_vs_floating.timing_scope_name(
      arithmetic_report.results[0].timing_scope,
    ),
    content="arithmetic_only",
  )
  inspect(
    @dzmingli_vs_floating.timing_scope_name(
      full_path_report.results[0].timing_scope,
    ),
    content="full_path",
  )
  inspect(
    arithmetic_report.jsonl.contains("\"type\":\"observation\""),
    content="true",
  )
  inspect(full_path_report.jsonl.contains("\"device\":\"cpu\""), content="true")
}

///|
test "Mare performance report renders both implementations" {
  let results : Array[@dzmingli_vs_floating.PerformanceResult] = [
    {
      operation: Add,
      timing_scope: OperationOnly,
      digits: 16,
      correctness_valid: true,
      dz_median_us: 1.0,
      gda_median_us: 2.0,
      gda_relative_delta_pct: 100.0,
      dz_speedup_vs_gda: 2.0,
      decision: "dzmingli_faster",
      samples: 60,
    },
    {
      operation: Add,
      timing_scope: FullPath,
      digits: 16,
      correctness_valid: true,
      dz_median_us: 3.0,
      gda_median_us: 4.0,
      gda_relative_delta_pct: 33.3,
      dz_speedup_vs_gda: 1.33,
      decision: "dzmingli_faster",
      samples: 60,
    },
  ]
  let html = @dzmingli_vs_floating.mare_performance_report_html(
    results,
    "native",
    "test-run",
    validation_count=4,
    failed_count=1,
  )
  assert_true(html.contains("<svg"))
  assert_true(html.contains("arithmetic_only"))
  assert_true(html.contains("full_path"))
  assert_true(html.contains("dzmingli_decimal"))
  assert_true(html.contains("floating_decimal_gda"))
  assert_true(html.contains("Total 4 · passed 3 · failed 1"))
}

///|
test "expanded scales create independent datasets per digit size" {
  assert_true(
    @dzmingli_vs_floating.expand_digit_scales([4, 16], 3) ==
    [4, 4, 4, 16, 16, 16],
  )
}

///|
test "division precision covers exact terminating quotients" {
  let left : @dzmingli_vs_floating.DecimalValue = {
    coefficient: @bigint.BigInt::from_string("9".repeat(4096)),
    scale: 0,
  }
  let right : @dzmingli_vs_floating.DecimalValue = {
    coefficient: 2N,
    scale: 0,
  }
  assert_true(
    @dzmingli_vs_floating.working_precision(Divide, left, right) >= 4096,
  )
}

///|
test "normalization removes trailing zeros" {
  let result = normalize({ coefficient: 1234500N, scale: 4 })
  inspect(result.coefficient.to_string(), content="12345")
  inspect(result.scale, content="2")
}

///|
test "canonical string preserves sign and leading fraction zeros" {
  inspect(canonical_string({ coefficient: -12N, scale: 4 }), content="-0.0012")
  inspect(canonical_string({ coefficient: 1200N, scale: 2 }), content="12")
}

///|
test "oracle multiplication truncates at 28 fractional digits" {
  let left : DecimalValue = { coefficient: 1N, scale: 20 }
  let right : DecimalValue = {
    coefficient: 12345678901234567890123456789N,
    scale: 10,
  }
  let result = oracle_multiply(left, right)
  inspect(canonical_string(result), content="0.0123456789012345678901234567")
}

///|
test "generated cases are reproducible" {
  let first = generate_cases(17, 4, Multiply)
  let second = generate_cases(17, 4, Multiply)
  inspect(first[0].left, content=second[0].left)
  inspect(first[3].right, content=second[3].right)
}

///|
test "generator places a negative sign before a leading fractional zero" {
  inspect(generate_decimal(0, 2, 4, true), content="-0.0018")
}

///|
test "GDA adapter matches x/decimal on aligned semantics" {
  let cases : Array[(Operation, DecimalValue, DecimalValue)] = [
    (Add, { coefficient: 12345N, scale: 2 }, { coefficient: -45N, scale: 1 }),
    (
      Subtract,
      { coefficient: -1200N, scale: 3 },
      { coefficient: 75N, scale: 2 },
    ),
    (
      Multiply,
      { coefficient: 123456789N, scale: 18 },
      { coefficient: 987654321N, scale: 18 },
    ),
    (Divide, { coefficient: 1N, scale: 0 }, { coefficient: 8N, scale: 0 }),
    (Compare, { coefficient: 100N, scale: 2 }, { coefficient: 999N, scale: 3 }),
  ]
  for item in cases {
    let (operation, left, right) = item
    let fixture = prepare_fixture(operation, left, right)
    let x_result = canonical_string(canonical_observation(run_x(fixture)))
    let gda_result = canonical_string(canonical_observation(run_gda(fixture)))
    inspect(gda_result, content=x_result)
  }
}

///|
test "large decimal comparisons normalize implementation-specific ordering" {
  let left = parse_decimal_value(
    "318642975318642975318642975318642975.3186429753186429753186429753",
  )
  let right = parse_decimal_value(
    "1864297531864297531864297531864297531864297531864297531864297531",
  )
  let fixture = prepare_fixture(Compare, left, right, semantics=ExactOverlap)
  let x_result = canonical_string(canonical_observation(run_x(fixture)))
  let gda_result = canonical_string(canonical_observation(run_gda(fixture)))
  inspect(x_result, content="-1")
  inspect(gda_result, content="-1")
}

///|
test "Mare Mark fingerprints are stable" {
  let cases = generate_cases(42, 2, Add)
  inspect(fingerprint_case(cases[0]), content=fingerprint_case(cases[0]))
  inspect(
    fingerprint_case(cases[0]) == fingerprint_case(cases[1]),
    content="false",
  )
}

///|
test "deterministic corpus agrees across X and GDA" {
  let operations : Array[Operation] = [Add, Subtract, Multiply, Divide, Compare]
  for operation in operations {
    for case in generate_cases(73, 20, operation) {
      let left = parse_decimal_value(case.left)
      let right = parse_decimal_value(case.right)
      let fixture = prepare_fixture(operation, left, right)
      let x_result = canonical_string(canonical_observation(run_x(fixture)))
      let gda_result = canonical_string(canonical_observation(run_gda(fixture)))
      inspect(gda_result, content=x_result)
    }
  }
}

///|
async test "Mare Mark smoke run validates and measures both implementations" {
  let report = run_mare_benchmark(
    [Add, Multiply],
    ExactOverlap,
    [4, 16],
    smoke_protocol(),
    42UL,
  )
  inspect(report.failed_count, content="0")
  inspect(report.validation_count, content="8")
  inspect(report.results.length(), content="4")
  inspect(report.results[0].samples, content="3")
  inspect(report.results[0].timing_scope, content="arithmetic_only")
  inspect(report.jsonl.contains("\"type\":\"observation\""), content="true")
  inspect(report.jsonl.contains("\"device\":\"cpu\""), content="true")
  inspect(
    report.jsonl.contains("\"frequency_policy\":\"uncontrolled\""),
    content="true",
  )
}

///|
test "Mare performance report renders Plot IR" {
  let results : Array[PerformanceResult] = [
    {
      operation: Add,
      semantics: ExactOverlap,
      timing_scope: "arithmetic_only",
      digits: 16,
      x_median_us: 1.0,
      gda_median_us: 2.0,
      gda_relative_delta_pct: 100.0,
      x_speedup_vs_gda: 2.0,
      decision: "x_faster",
      samples: 60,
    },
  ]
  let html = mare_performance_report_html(
    results,
    "native",
    "test-run",
    validation_count=2,
  )
  assert_true(html.contains("<svg"))
  assert_true(html.contains("arithmetic_only"))
  assert_true(html.contains("x_decimal"))
  assert_true(html.contains("Total 2 · passed 2 · failed 0"))
}

///|
test "expanded scales create independent datasets per digit size" {
  assert_true(expand_digit_scales([4, 16], 3) == [4, 4, 4, 16, 16, 16])
}

///|
test "division precision follows the requested semantic contract" {
  let left : DecimalValue = {
    coefficient: @bigint.BigInt::from_string("9".repeat(4096)),
    scale: 0,
  }
  let balanced_right : DecimalValue = {
    coefficient: @bigint.BigInt::from_string("7".repeat(4096)),
    scale: 0,
  }
  let exact_right : DecimalValue = { coefficient: 2N, scale: 0 }
  assert_eq(
    working_precision(Divide, left, balanced_right, semantics=XCompatible),
    31,
  )
  assert_eq(
    working_precision(Divide, left, exact_right, semantics=ExactOverlap),
    4097,
  )
}

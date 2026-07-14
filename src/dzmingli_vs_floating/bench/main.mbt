///|
fn write_mare_performance_report(
  results : Array[@decimal_bench.PerformanceResult],
  validation_count : Int,
  failed_count : Int,
) -> Unit {
  try @fs.create_dir("artifacts") catch {
    _ => ()
  } noraise {
    _ => ()
  }
  let html = @decimal_bench.mare_performance_report_html(
    results,
    "native",
    "dzmingli-vs-floating-gda",
    validation_count~,
    failed_count~,
  )
  try
    @fs.write_string_to_file(
      "artifacts/mare_mark_dzmingli_vs_floating_performance.html", html,
    )
  catch {
    _ => abort("could not write Mare Mark performance report")
  } noraise {
    _ => ()
  }
}

///|
fn benchmark_digit_scales() -> Array[Int] {
  let digit_scales = @decimal_bench.expand_digit_scales(
    [1, 4, 16, 64, 256, 1024, 4096],
    3,
  )
  digit_scales.append(@decimal_bench.expand_digit_scales([8192, 10000], 3))
  digit_scales
}

///|
fn non_multiplication_stress_scales() -> Array[Int] {
  @decimal_bench.expand_digit_scales([16384, 20000], 3)
}

///|
fn extended_arithmetic_operations() -> Array[@decimal_bench.Operation] {
  [
    @decimal_bench.Operation::DivideInteger,
    @decimal_bench.Operation::Remainder,
    @decimal_bench.Operation::Power,
    @decimal_bench.Operation::Fma,
    @decimal_bench.Operation::SquareRoot,
    @decimal_bench.Operation::Plus,
    @decimal_bench.Operation::Minus,
    @decimal_bench.Operation::Abs,
    @decimal_bench.Operation::Quantize,
    @decimal_bench.Operation::Rescale,
    @decimal_bench.Operation::ScaleB,
    @decimal_bench.Operation::Reduce,
    @decimal_bench.Operation::ToIntegralExact,
    @decimal_bench.Operation::ToIntegralValue,
  ]
}

///|
async fn main {
  let operations : Array[@decimal_bench.Operation] = [
    @decimal_bench.Operation::Add,
    @decimal_bench.Operation::Subtract,
    @decimal_bench.Operation::Multiply,
    @decimal_bench.Operation::Divide,
    @decimal_bench.Operation::Compare,
  ]
  let digit_scales = benchmark_digit_scales()
  let arithmetic_report = @decimal_bench.run_mare_benchmark(
    operations,
    @decimal_bench.TimingScope::OperationOnly,
    digit_scales,
    @decimal_bench.default_benchmark_protocol(),
    0xDEC1A1UL,
  )
  println(arithmetic_report.jsonl)
  for result in arithmetic_report.results {
    println(result.to_json())
  }
  let full_path_report = @decimal_bench.run_mare_benchmark(
    operations,
    @decimal_bench.TimingScope::FullPath,
    digit_scales,
    @decimal_bench.default_benchmark_protocol(),
    0xDEC1A1UL,
  )
  println(full_path_report.jsonl)
  for result in full_path_report.results {
    println(result.to_json())
  }
  let stress_operations : Array[@decimal_bench.Operation] = [
    @decimal_bench.Operation::Add,
    @decimal_bench.Operation::Subtract,
    @decimal_bench.Operation::Divide,
    @decimal_bench.Operation::Compare,
  ]
  let stress_scales = non_multiplication_stress_scales()
  let arithmetic_stress_report = @decimal_bench.run_mare_benchmark(
    stress_operations,
    @decimal_bench.TimingScope::OperationOnly,
    stress_scales,
    @decimal_bench.default_benchmark_protocol(),
    0xDEC1A1UL,
  )
  println(arithmetic_stress_report.jsonl)
  for result in arithmetic_stress_report.results {
    println(result.to_json())
  }
  let full_path_stress_report = @decimal_bench.run_mare_benchmark(
    stress_operations,
    @decimal_bench.TimingScope::FullPath,
    stress_scales,
    @decimal_bench.default_benchmark_protocol(),
    0xDEC1A1UL,
  )
  println(full_path_stress_report.jsonl)
  for result in full_path_stress_report.results {
    println(result.to_json())
  }
  let extended_operations = extended_arithmetic_operations()
  let extended_scales = @decimal_bench.expand_digit_scales(
    [1, 16, 64, 256, 1024],
    3,
  )
  let arithmetic_extended_report = @decimal_bench.run_mare_benchmark(
    extended_operations,
    @decimal_bench.TimingScope::OperationOnly,
    extended_scales,
    @decimal_bench.default_benchmark_protocol(),
    0xDEC1A1UL,
  )
  println(arithmetic_extended_report.jsonl)
  for result in arithmetic_extended_report.results {
    println(result.to_json())
  }
  let full_path_extended_report = @decimal_bench.run_mare_benchmark(
    extended_operations,
    @decimal_bench.TimingScope::FullPath,
    extended_scales,
    @decimal_bench.default_benchmark_protocol(),
    0xDEC1A1UL,
  )
  println(full_path_extended_report.jsonl)
  for result in full_path_extended_report.results {
    println(result.to_json())
  }
  let all_results = []
  all_results.append(arithmetic_report.results)
  all_results.append(full_path_report.results)
  all_results.append(arithmetic_stress_report.results)
  all_results.append(full_path_stress_report.results)
  all_results.append(arithmetic_extended_report.results)
  all_results.append(full_path_extended_report.results)
  let validation_count = arithmetic_report.validation_count +
    full_path_report.validation_count +
    arithmetic_stress_report.validation_count +
    full_path_stress_report.validation_count +
    arithmetic_extended_report.validation_count +
    full_path_extended_report.validation_count
  let failed_count = arithmetic_report.failed_count +
    full_path_report.failed_count +
    arithmetic_stress_report.failed_count +
    full_path_stress_report.failed_count +
    arithmetic_extended_report.failed_count +
    full_path_extended_report.failed_count
  write_mare_performance_report(all_results, validation_count, failed_count)
  if failed_count > 0 {
    abort("decimal differential validation failed")
  }
}

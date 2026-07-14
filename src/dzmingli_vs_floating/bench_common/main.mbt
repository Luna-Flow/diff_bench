///|
fn write_common_digits_report(
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
    "dzmingli-vs-floating-gda-common-digits",
    validation_count~,
    failed_count~,
  )
  try
    @fs.write_string_to_file(
      "artifacts/mare_mark_dzmingli_vs_floating_common_digits.html", html,
    )
  catch {
    _ => abort("could not write common-digits Mare Mark report")
  } noraise {
    _ => ()
  }
}

///|
async fn main {
  let operations : Array[@decimal_bench.Operation] = [
    @decimal_bench.Operation::Add,
    @decimal_bench.Operation::Subtract,
    @decimal_bench.Operation::Multiply,
    @decimal_bench.Operation::Divide,
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
    @decimal_bench.Operation::Compare,
  ]
  let common_digits = [1, 4, 8, 16, 18, 28]
  let digit_scales = @decimal_bench.expand_digit_scales(common_digits, 3)
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
  let all_results = []
  all_results.append(arithmetic_report.results)
  all_results.append(full_path_report.results)
  let validation_count = arithmetic_report.validation_count +
    full_path_report.validation_count
  let failed_count = arithmetic_report.failed_count +
    full_path_report.failed_count
  write_common_digits_report(all_results, validation_count, failed_count)
  if failed_count > 0 {
    abort("common-digits decimal differential validation failed")
  }
}

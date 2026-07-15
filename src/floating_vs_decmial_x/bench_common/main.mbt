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
  try @fs.create_dir("artifacts/floating_vs_decmial_x") catch {
    _ => ()
  } noraise {
    _ => ()
  }
  let html = @decimal_bench.mare_performance_report_html(
    results,
    "native",
    "floating-vs-decimal-x-common-digits",
    validation_count~,
    failed_count~,
  )
  try
    @fs.write_string_to_file(
      "artifacts/floating_vs_decmial_x/common_digits.html", html,
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
    @decimal_bench.Operation::Compare,
  ]
  let common_digits = [1, 4, 8, 16, 18, 28]
  let digit_scales = @decimal_bench.expand_digit_scales(common_digits, 3)
  let report = @decimal_bench.run_mare_benchmark(
    operations,
    @decimal_bench.DecimalSemantics::ExactOverlap,
    digit_scales,
    @decimal_bench.default_benchmark_protocol(),
    0xDEC1A1UL,
  )
  println(report.jsonl)
  for result in report.results {
    println(result.to_json())
  }
  let x_compatible_report = @decimal_bench.run_mare_benchmark(
    [@decimal_bench.Operation::Multiply, @decimal_bench.Operation::Divide],
    @decimal_bench.DecimalSemantics::XCompatible,
    digit_scales,
    @decimal_bench.default_benchmark_protocol(),
    0xDEC1A1UL,
  )
  println(x_compatible_report.jsonl)
  for result in x_compatible_report.results {
    println(result.to_json())
  }
  let all_results = []
  all_results.append(report.results)
  all_results.append(x_compatible_report.results)
  let validation_count = report.validation_count +
    x_compatible_report.validation_count
  let failed_count = report.failed_count + x_compatible_report.failed_count
  write_common_digits_report(all_results, validation_count, failed_count)
  if failed_count > 0 {
    abort("common-digits decimal differential validation failed")
  }
}

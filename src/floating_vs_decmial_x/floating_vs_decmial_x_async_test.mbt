///|
async test "Mare Mark smoke run validates and measures both implementations" {
  let report = @floating_vs_decmial_x.run_mare_benchmark(
    [Add, Multiply],
    ExactOverlap,
    [4, 16],
    @floating_vs_decmial_x.smoke_protocol(),
    42UL,
  )
  inspect(report.failed_count, content="0")
  inspect(report.validation_count, content="8")
  inspect(report.results.length(), content="4")
  inspect(report.results[0].samples, content="3")
  inspect(report.results[0].timing_scope, content="arithmetic_only")
  inspect(
    report.results[0].to_json().contains("\"artifact_version\":\"mmka_1\""),
    content="true",
  )
  inspect(report.jsonl.contains("\"type\":\"observation\""), content="true")
  inspect(report.jsonl.contains("\"device\":\"cpu\""), content="true")
  inspect(
    report.jsonl.contains("\"frequency_policy\":\"uncontrolled\""),
    content="true",
  )
}

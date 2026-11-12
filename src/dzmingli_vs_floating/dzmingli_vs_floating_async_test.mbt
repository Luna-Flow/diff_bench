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

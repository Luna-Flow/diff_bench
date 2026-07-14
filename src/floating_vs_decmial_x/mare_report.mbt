///|
fn report_timing_scope(semantics : DecimalSemantics) -> String {
  match semantics {
    ExactOverlap => "arithmetic_only"
    XCompatible => "semantic_equivalent_pipeline"
  }
}

///|
fn report_matches(
  result : PerformanceResult,
  operation : Operation,
  semantics : DecimalSemantics,
) -> Bool {
  operation_name(result.operation) == operation_name(operation) &&
  decimal_semantics_name(result.semantics) == decimal_semantics_name(semantics)
}

///|
fn report_operation_plot(
  results : Array[PerformanceResult],
  operation : Operation,
  semantics : DecimalSemantics,
) -> @mare_ir.Plot? {
  let points = []
  for result in results {
    if report_matches(result, operation, semantics) {
      points.push(
        @mare_ir.PlotPoint::new(
          result.digits.to_string(),
          result.x_median_us,
          "x_decimal",
        ),
      )
      points.push(
        @mare_ir.PlotPoint::new(
          result.digits.to_string(),
          result.gda_median_us,
          "floating_decimal_gda",
        ),
      )
    }
  }
  if points.is_empty() {
    None
  } else {
    Some(
      @mare_ir.Plot::new(
        @mare_ir.PlotKind::Scaling,
        report_timing_scope(semantics) +
        " · " +
        operation_name(operation) +
        " · median latency",
        "µs/op",
        "median",
        points,
      ),
    )
  }
}

///|
fn report_speedup_plot(
  results : Array[PerformanceResult],
  semantics : DecimalSemantics,
) -> @mare_ir.Plot? {
  let points = []
  for result in results {
    if decimal_semantics_name(result.semantics) ==
      decimal_semantics_name(semantics) {
      points.push(
        @mare_ir.PlotPoint::new(
          result.digits.to_string(),
          result.x_speedup_vs_gda,
          operation_name(result.operation),
        ),
      )
    }
  }
  if points.is_empty() {
    None
  } else {
    Some(
      @mare_ir.Plot::new(
        @mare_ir.PlotKind::Scaling,
        report_timing_scope(semantics) + " · X speedup versus GDA",
        "×",
        "median",
        points,
      ),
    )
  }
}

///|
pub fn mare_performance_report_document(
  results : Array[PerformanceResult],
  target : String,
  run_id : String,
  validation_count? : Int = 0,
  failed_count? : Int = 0,
) -> @mare_ir.PlotDocument {
  let plots = []
  let operations : Array[Operation] = [Add, Subtract, Multiply, Divide, Compare]
  for semantics in [ExactOverlap, XCompatible] {
    for operation in operations {
      match report_operation_plot(results, operation, semantics) {
        Some(plot) => plots.push(plot)
        None => ()
      }
    }
    match report_speedup_plot(results, semantics) {
      Some(plot) => plots.push(plot)
      None => ()
    }
  }
  let corpus = @mare_ir.CorpusSummary::new(
    validation_count + failed_count,
    validation_count,
    failed_count,
    0,
    0,
  )
  @mare_ir.PlotDocument::new(
    run_id,
    target,
    plots,
    differential=@mare_ir.DifferentialReport::new([], [], [], corpus),
  )
}

///|
pub fn mare_performance_report_html(
  results : Array[PerformanceResult],
  target : String,
  run_id : String,
  validation_count? : Int = 0,
  failed_count? : Int = 0,
) -> String {
  @mare_report.html(
    mare_performance_report_document(
      results,
      target,
      run_id,
      validation_count~,
      failed_count~,
    ),
  )
}

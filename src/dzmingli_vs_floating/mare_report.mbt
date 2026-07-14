///|
fn report_matches(
  result : PerformanceResult,
  operation : Operation,
  timing_scope : TimingScope,
) -> Bool {
  operation_name(result.operation) == operation_name(operation) &&
  timing_scope_name(result.timing_scope) == timing_scope_name(timing_scope)
}

///|
fn report_operation_plot(
  results : Array[PerformanceResult],
  operation : Operation,
  timing_scope : TimingScope,
) -> @mare_ir.Plot? {
  let points = []
  for result in results {
    if report_matches(result, operation, timing_scope) {
      if result.correctness_valid {
        points.push(
          @mare_ir.PlotPoint::new(
            result.digits.to_string(),
            result.dz_median_us,
            "dzmingli_decimal",
          ),
        )
      }
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
        timing_scope_name(timing_scope) +
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
  timing_scope : TimingScope,
) -> @mare_ir.Plot? {
  let points = []
  for result in results {
    if result.correctness_valid &&
      timing_scope_name(result.timing_scope) == timing_scope_name(timing_scope) {
      points.push(
        @mare_ir.PlotPoint::new(
          result.digits.to_string(),
          result.dz_speedup_vs_gda,
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
        timing_scope_name(timing_scope) +
        " · DzmingLi speedup versus floating GDA",
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
  let operations : Array[Operation] = [
    Add,
    Subtract,
    Multiply,
    Divide,
    DivideInteger,
    Remainder,
    Power,
    Fma,
    SquareRoot,
    Plus,
    Minus,
    Abs,
    Quantize,
    Rescale,
    ScaleB,
    Reduce,
    ToIntegralExact,
    ToIntegralValue,
    Compare,
  ]
  for timing_scope in [OperationOnly, FullPath] {
    for operation in operations {
      match report_operation_plot(results, operation, timing_scope) {
        Some(plot) => plots.push(plot)
        None => ()
      }
    }
    match report_speedup_plot(results, timing_scope) {
      Some(plot) => plots.push(plot)
      None => ()
    }
  }
  let passed_count = validation_count - failed_count
  let corpus = @mare_ir.CorpusSummary::new(
    validation_count, passed_count, failed_count, 0, 0,
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

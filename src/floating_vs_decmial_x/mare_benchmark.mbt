///|
pub(all) struct MareDecimalInput {
  left : DecimalValue
  right : DecimalValue
  operation : Operation
  semantics : DecimalSemantics
  digits : Int
  left_scale : Int
  right_scale : Int
}

///|
pub(all) struct PerformanceResult {
  operation : Operation
  semantics : DecimalSemantics
  timing_scope : String
  digits : Int
  x_median_us : Double
  gda_median_us : Double
  gda_relative_delta_pct : Double
  x_speedup_vs_gda : Double
  decision : String
  samples : Int
}

///|
pub(all) struct MareBenchmarkReport {
  results : Array[PerformanceResult]
  jsonl : String
  validation_count : Int
  failed_count : Int
}

///|
pub fn PerformanceResult::to_json(self : PerformanceResult) -> String {
  "{\"artifact_version\":\"" +
  @mare_model.ArtifactVersion::V1.identifier() +
  "\",\"type\":\"comparison\",\"operation\":\"" +
  operation_name(self.operation) +
  "\",\"semantics\":\"" +
  decimal_semantics_name(self.semantics) +
  "\",\"timing_scope\":\"" +
  self.timing_scope +
  "\",\"digits\":" +
  self.digits.to_string() +
  ",\"x_median_us\":" +
  self.x_median_us.to_string() +
  ",\"gda_median_us\":" +
  self.gda_median_us.to_string() +
  ",\"gda_relative_delta_pct\":" +
  self.gda_relative_delta_pct.to_string() +
  ",\"x_speedup_vs_gda\":" +
  self.x_speedup_vs_gda.to_string() +
  ",\"decision\":\"" +
  self.decision +
  "\",\"samples\":" +
  self.samples.to_string() +
  "}"
}

///|
pub fn decimal_semantics_name(semantics : DecimalSemantics) -> String {
  match semantics {
    ExactOverlap => "exact_overlap"
    XCompatible => "x_compatible"
  }
}

///|
fn benchmark_timing_scope(
  operation : Operation,
  semantics : DecimalSemantics,
) -> String {
  match (operation, semantics) {
    (Multiply, XCompatible) | (Divide, XCompatible) =>
      "semantic_equivalent_pipeline"
    _ => "arithmetic_only"
  }
}

///|
fn decimal_scales(
  operation : Operation,
  semantics : DecimalSemantics,
  dataset_id : Int,
) -> (Int, Int) {
  match semantics {
    ExactOverlap =>
      match operation {
        Multiply => {
          let left_scales = [0, 2, 5, 8, 12, 14]
          let left_scale = left_scales[dataset_id % left_scales.length()]
          (left_scale, 14 - left_scale)
        }
        Divide => (0, 0)
        Add | Subtract | Compare | Parse | Format => {
          let scales = [0, 2, 8, 18, 28]
          (
            scales[dataset_id % scales.length()],
            scales[(dataset_id + 1) % scales.length()],
          )
        }
      }
    XCompatible =>
      match operation {
        Multiply => {
          let scales = [15, 18, 24, 28]
          (
            scales[dataset_id % scales.length()],
            scales[(dataset_id + 1) % scales.length()],
          )
        }
        Divide => {
          let scales = [0, 2, 8, 18, 28]
          (
            scales[dataset_id % scales.length()],
            scales[(dataset_id + 2) % scales.length()],
          )
        }
        Add | Subtract | Compare | Parse | Format => {
          let scales = [0, 2, 8, 18, 28]
          (
            scales[dataset_id % scales.length()],
            scales[(dataset_id + 1) % scales.length()],
          )
        }
      }
  }
}

///|
fn exact_divisor(dataset_id : Int) -> DecimalValue {
  let divisors : Array[DecimalValue] = [
    { coefficient: 2N, scale: 0 },
    { coefficient: 4N, scale: 0 },
    { coefficient: 5N, scale: 0 },
    { coefficient: 8N, scale: 0 },
    { coefficient: 25N, scale: 0 },
  ]
  divisors[dataset_id % divisors.length()]
}

///|
fn materialize_mare_input(
  operation : Operation,
  semantics : DecimalSemantics,
  context : @mare_model.GenerationContext[Int],
) -> MareDecimalInput {
  let digits = context.dataset_key.scale
  let (left_scale, right_scale) = decimal_scales(
    operation,
    semantics,
    context.dataset_key.dataset_id,
  )
  let derived = @mare_generator.derive_seed(
    context.seed,
    operation_name(operation),
    context.dataset_key.dataset_id,
  )
  let seed = derived.to_int()
  let left = parse_decimal_value(
    generate_decimal(seed, digits, left_scale, seed % 3 == 0),
  )
  let right = if uses_exact_division_input(operation, semantics) {
    exact_divisor(context.dataset_key.dataset_id)
  } else {
    parse_decimal_value(
      generate_decimal(seed + 97, digits, right_scale, seed % 5 == 0),
    )
  }
  { left, right, operation, semantics, digits, left_scale, right_scale }
}

///|
fn uses_exact_division_input(
  operation : Operation,
  semantics : DecimalSemantics,
) -> Bool {
  match (operation, semantics) {
    (Divide, ExactOverlap) => true
    _ => false
  }
}

///|
fn mare_input_text(input : MareDecimalInput) -> String {
  operation_name(input.operation) +
  "|" +
  decimal_semantics_name(input.semantics) +
  "|" +
  input.digits.to_string() +
  "|" +
  canonical_string(input.left) +
  "|" +
  canonical_string(input.right)
}

///|
fn observation_token(observation : DecimalObservation) -> Int {
  match observation {
    X(value) => value.signum()
    XCompare(value) => value
    Gda(outcome) => {
      let value = outcome.value()
      if value.is_zero() {
        0
      } else if value.is_negative() {
        -1
      } else {
        1
      }
    }
  }
}

///|
fn validation_status(
  expected : @mare_model.ExecutionOutcome[DecimalValue],
  actual : @mare_model.ExecutionOutcome[DecimalObservation],
) -> @mare_model.ValidationStatus {
  match (expected, actual) {
    (
      @mare_model.ExecutionOutcome::Value(expected),
      @mare_model.ExecutionOutcome::Value(actual),
    ) =>
      if canonical_string(expected) ==
        canonical_string(canonical_observation(actual)) {
        @mare_model.ValidationStatus::Valid
      } else {
        @mare_model.ValidationStatus::Invalid("canonical decimal mismatch")
      }
    _ => @mare_model.ValidationStatus::Invalid("unexpected execution outcome")
  }
}

///|
fn mare_fixture(
  operation : Operation,
  semantics : DecimalSemantics,
) -> @mare_fixture.Fixture[Int, MareDecimalInput, DecimalFixture] {
  @mare_fixture.Fixture::new(
    "floating-vs-decimal-x",
    "decimal-neutral-v1",
    context => materialize_mare_input(operation, semantics, context),
    input => @mare_generator.stable_fingerprint(mare_input_text(input)),
    input => input,
    (input, _, _) => {
      prepare_fixture(
        input.operation,
        input.left,
        input.right,
        semantics=input.semantics,
      )
    },
    (_, _) => (),
    @mare_model.SetupPolicy::new(
      @mare_model.SetupFrequency::PerDataset,
      @mare_model.SetupTiming::ExcludedFromMeasurement,
      @mare_model.WorkspaceScope::DatasetWorkspace,
    ),
  )
}

///|
fn mare_oracle(
  operation : Operation,
) -> @mare_experiment.ReferenceOracle[
  MareDecimalInput,
  DecimalValue,
  DecimalObservation,
  Unit,
] {
  @mare_experiment.ReferenceOracle::new(
    "decimal-bigint-oracle-v1",
    () => (),
    _ => 1,
    (input, _, context) => {
      @mare_model.OperationResult::completed(
        oracle_operation(operation, input.left, input.right).value,
        context,
      )
    },
    (_, _, expected, actual) => validation_status(expected, actual),
    canonical_string,
  )
}

///|
fn mare_case(
  operation : Operation,
  semantics : DecimalSemantics,
  digit_scales : Array[Int],
) -> @mare_runner.BenchSpec[
  Int,
  MareDecimalInput,
  DecimalFixture,
  DecimalValue,
  DecimalObservation,
  Unit,
  DecimalObservation?,
  Int,
] {
  let x_implementation = @mare_runner.Implementation::in_process(
    "x_decimal",
    "moonbitlang/x@0.4.46",
    () => (),
    (prepared, context) => {
      @mare_model.OperationResult::completed(run_x(prepared), context)
    },
  )
  let gda_implementation = @mare_runner.Implementation::in_process(
    "floating_decimal_gda",
    "Luna-Flow/floating@0.6.1",
    () => (),
    (prepared, context) => {
      @mare_model.OperationResult::completed(run_gda(prepared), context)
    },
  )
  @mare_runner.BenchSpec::advanced(
    "decimal_" +
    operation_name(operation) +
    "_" +
    decimal_semantics_name(semantics),
    mare_fixture(operation, semantics),
    [x_implementation, gda_implementation],
    @mare_runner.OutputSink::new(() => None, (_, output) => Some(output), last => {
      match last {
        Some(output) => observation_token(output)
        None => 0
      }
    }),
    @mare_experiment.OracleSpec::Reference(mare_oracle(operation)),
    digit_scales,
    digits => digits.to_string(),
    1,
    (input, _) => {
      @mare_model.CaseDescriptor::new(
        operation_name(input.operation),
        [canonical_string(input.left), canonical_string(input.right)],
        decimal_semantics_name(input.semantics),
        "toward-zero",
      )
    },
    mare_input_text,
    observation => canonical_string(canonical_observation(observation)),
    _ => "stateless",
    (input, implementation_id) => {
      @mare_model.ReplaySpec::new("moon", [
        "run",
        "--release",
        "src/floating_vs_decmial_x/bench",
        "--target",
        "native",
        "--",
        operation_name(input.operation),
        input.digits.to_string(),
        implementation_id,
      ])
    },
  )
}

///|
pub fn smoke_protocol() -> @mare_model.RunProtocol {
  @mare_model.RunProtocol::new(
    @mare_model.ExperimentDesign::FixedDatasetRepeatedMeasurements,
    2,
    None,
    @mare_model.CalibrationProtocol::new(
      500.0,
      1,
      100_000,
      5_000.0,
      @mare_model.BatchPolicy::PerImplementation,
    ),
    3.0,
    @mare_model.OrderPolicy::BalancedBlocks(0xDEC1A1UL),
    @mare_model.OutlierPolicy::ReportOnly,
    @mare_model.ValidationCoverage::EveryDataset,
    0,
    3,
  )
}

///|
pub fn default_benchmark_protocol() -> @mare_model.RunProtocol {
  @mare_model.RunProtocol::new(
    @mare_model.ExperimentDesign::FixedDatasetRepeatedMeasurements,
    5,
    Some(20_000.0),
    @mare_model.CalibrationProtocol::new(
      5_000.0,
      1,
      10_000_000,
      20_000.0,
      @mare_model.BatchPolicy::PerImplementation,
    ),
    3.0,
    @mare_model.OrderPolicy::BalancedBlocks(0xDEC1A1UL),
    @mare_model.OutlierPolicy::ReportOnly,
    @mare_model.ValidationCoverage::EveryDataset,
    0,
    20,
  )
}

///|
fn benchmark_environment_value(key : String, fallback : String) -> String {
  match @env.get_env_var(key) {
    Some(value) => if value == "" { fallback } else { value }
    None => fallback
  }
}

///|
fn benchmark_execution_target() -> @mare_model.ExecutionTarget {
  match benchmark_environment_value("MARE_TARGET", "native") {
    "js" => @mare_model.ExecutionTarget::Js
    "wasm" => @mare_model.ExecutionTarget::Wasm
    "wasm-gc" => @mare_model.ExecutionTarget::WasmGc
    "llvm" => @mare_model.ExecutionTarget::Llvm
    "native" => @mare_model.ExecutionTarget::Native
    other => @mare_model.ExecutionTarget::Custom(other)
  }
}

///|
pub fn benchmark_environment() -> @mare_model.EnvironmentSnapshot {
  @mare_model.EnvironmentSnapshot::new(
    @mare_model.SemanticEnvironment::new(
      benchmark_execution_target(),
      benchmark_environment_value("MARE_COMPILER", "moon-unknown"),
      benchmark_environment_value("MARE_BUILD_MODE", "unspecified"),
      "decimal-gda-v1",
    ),
    @mare_model.PerformanceEnvironment::new(
      "moon-native",
      benchmark_environment_value("MARE_CPU", "unknown"),
      "moon-gc",
      1,
      "mare-mark-bench",
      device=benchmark_environment_value("MARE_DEVICE", "cpu"),
      frequency_policy=benchmark_environment_value(
        "MARE_FREQUENCY_POLICY", "uncontrolled",
      ),
    ),
    @mare_model.ProvenanceEnvironment::new(
      benchmark_environment_value("MARE_OS", "unknown"),
      benchmark_environment_value("MARE_EXECUTION_CONTEXT", "local"),
      benchmark_environment_value("MARE_REPOSITORY_STATE", "unspecified"),
      "workspace",
      "floating-vs-decimal-x",
    ),
  )
}

///|
fn decision_name(decision : @mare_stats.Decision) -> String {
  match decision {
    Faster => "gda_faster"
    Slower => "x_faster"
    Equivalent => "equivalent"
    Invalid => "invalid"
    Unknown => "unknown"
  }
}

///|
fn performance_results(
  operation : Operation,
  semantics : DecimalSemantics,
  digit_scales : Array[Int],
  observations : Array[@mare_model.Observation],
) -> Array[PerformanceResult] {
  let results = []
  let reported_digits = []
  for digits in digit_scales {
    let mut already_reported = false
    for reported in reported_digits {
      if reported == digits {
        already_reported = true
      }
    }
    if already_reported {
      continue
    }
    reported_digits.push(digits)
    let (x_samples, gda_samples) = paired_samples_for_digits(
      digits, digit_scales, observations,
    )
    let comparison = @mare_stats.compare_paired(
      "x_decimal",
      "floating_decimal_gda",
      x_samples,
      gda_samples,
      3.0,
      @mare_model.confirmatory_interval(),
    )
    let x_stats = @mare_stats.summarize(x_samples)
    let gda_stats = @mare_stats.summarize(gda_samples)
    results.push({
      operation,
      semantics,
      timing_scope: benchmark_timing_scope(operation, semantics),
      digits,
      x_median_us: x_stats.median,
      gda_median_us: gda_stats.median,
      gda_relative_delta_pct: comparison.relative_delta_pct,
      x_speedup_vs_gda: if x_stats.median == 0.0 {
        1.0
      } else {
        gda_stats.median / x_stats.median
      },
      decision: decision_name(comparison.decision),
      samples: comparison.valid_samples,
    })
  }
  results
}

///|
fn paired_samples_for_digits(
  digits : Int,
  digit_scales : Array[Int],
  observations : Array[@mare_model.Observation],
) -> (Array[Double], Array[Double]) {
  let x_samples = []
  let gda_samples = []
  for baseline in observations {
    if baseline.implementation_id != "x_decimal" ||
      baseline.phase.text() != "confirmatory" ||
      !baseline.valid ||
      digit_scales[baseline.dataset_id] != digits {
      continue
    }
    for candidate in observations {
      if candidate.implementation_id == "floating_decimal_gda" &&
        candidate.phase.text() == baseline.phase.text() &&
        candidate.valid &&
        candidate.dataset_id == baseline.dataset_id &&
        candidate.repetition_id == baseline.repetition_id &&
        candidate.block_id == baseline.block_id {
        x_samples.push(baseline.raw_elapsed_us)
        gda_samples.push(candidate.raw_elapsed_us)
        break
      }
    }
  }
  (x_samples, gda_samples)
}

///|
pub async fn run_mare_benchmark(
  operations : Array[Operation],
  semantics : DecimalSemantics,
  digit_scales : Array[Int],
  protocol : @mare_model.RunProtocol,
  seed : UInt64,
) -> MareBenchmarkReport {
  let results = []
  let jsonl_parts = []
  let mut validation_count = 0
  let mut failed_count = 0
  for operation in operations {
    let memory = @mare_event.InMemorySink::new()
    let jsonl = @mare_event.JsonlSink::new()
    let sink = @mare_event.tee(memory.as_sink(), jsonl.as_sink())
    let plan = mare_case(operation, semantics, digit_scales).compile().unwrap()
    let validated_protocol = @mare_runner.validate_protocol(protocol).unwrap()
    let summary = @mare_runner.run(
      plan,
      @mare_runner.RunContext::new(
        benchmark_environment(),
        sink,
        seed,
        validated_protocol,
      ),
    )
    validation_count = validation_count + summary.validation_count
    failed_count = failed_count + summary.failed_count
    results.append(
      performance_results(
        operation,
        semantics,
        digit_scales,
        memory.observations,
      ),
    )
    jsonl_parts.push(jsonl.to_jsonl())
  }
  { results, jsonl: jsonl_parts.join("\n"), validation_count, failed_count }
}

///|
pub fn expand_digit_scales(
  digit_scales : Array[Int],
  datasets_per_scale : Int,
) -> Array[Int] {
  let expanded = []
  for digits in digit_scales {
    let mut dataset_index = 0
    while dataset_index < datasets_per_scale {
      expanded.push(digits)
      dataset_index = dataset_index + 1
    }
  }
  expanded
}

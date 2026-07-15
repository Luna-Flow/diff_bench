///|
pub(all) struct MareDecimalInput {
  left : DecimalValue
  right : DecimalValue
  third : DecimalValue
  operation : Operation
  timing_scope : TimingScope
  digits : Int
  left_scale : Int
  right_scale : Int
}

///|
pub(all) struct PerformanceResult {
  operation : Operation
  timing_scope : TimingScope
  digits : Int
  correctness_valid : Bool
  dz_median_us : Double
  gda_median_us : Double
  gda_relative_delta_pct : Double
  dz_speedup_vs_gda : Double
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
pub fn timing_scope_name(timing_scope : TimingScope) -> String {
  match timing_scope {
    OperationOnly => "arithmetic_only"
    FullPath => "full_path"
  }
}

///|
pub fn PerformanceResult::to_json(self : PerformanceResult) -> String {
  "{\"artifact_version\":\"" +
  @mare_model.ArtifactVersion::V1.identifier() +
  "\",\"type\":\"comparison\",\"operation\":\"" +
  operation_name(self.operation) +
  "\",\"timing_scope\":\"" +
  timing_scope_name(self.timing_scope) +
  "\",\"digits\":" +
  self.digits.to_string() +
  ",\"correctness_valid\":" +
  self.correctness_valid.to_string() +
  ",\"dz_median_us\":" +
  self.dz_median_us.to_string() +
  ",\"gda_median_us\":" +
  self.gda_median_us.to_string() +
  ",\"gda_relative_delta_pct\":" +
  self.gda_relative_delta_pct.to_string() +
  ",\"dz_speedup_vs_gda\":" +
  self.dz_speedup_vs_gda.to_string() +
  ",\"decision\":\"" +
  self.decision +
  "\",\"samples\":" +
  self.samples.to_string() +
  "}"
}

///|
fn decimal_scales(operation : Operation, dataset_id : Int) -> (Int, Int) {
  let left_scales = [0, 8, 28]
  let right_scales = [2, 18, 0]
  let profile = dataset_id % left_scales.length()
  match operation {
    Divide | DivideInteger | Remainder | Power | Rescale | ScaleB =>
      (left_scales[profile], 0)
    SquareRoot
    | Plus
    | Minus
    | Abs
    | Reduce
    | ToIntegralExact
    | ToIntegralValue => (0, 0)
    Add | Subtract | Multiply | Fma | Quantize | Compare | Parse | Format =>
      (left_scales[profile], right_scales[profile])
  }
}

///|
fn exact_divisor(dataset_id : Int) -> DecimalValue {
  let divisors : Array[DecimalValue] = [
    { coefficient: 2N, scale: 0 },
    { coefficient: 8N, scale: 0 },
    { coefficient: 25N, scale: 0 },
  ]
  divisors[dataset_id % divisors.length()]
}

///|
fn materialize_mare_input(
  operation : Operation,
  timing_scope : TimingScope,
  digit_scales : Array[Int],
  context : @mare_model.GenerationContext[Int],
) -> MareDecimalInput {
  let digits = context.dataset_key.scale
  let profile = dataset_profile(digit_scales, context.dataset_key.dataset_id)
  let (left_scale, generated_right_scale) = decimal_scales(operation, profile)
  let derived = @mare_generator.derive_seed(
    context.seed,
    operation_name(operation) + ":" + digits.to_string(),
    profile,
  )
  let seed = derived.to_int()
  let generated_left = parse_decimal_value(
    generate_decimal(seed, digits, left_scale, seed % 3 == 0),
  )
  let left = match operation {
    SquareRoot => multiply(generated_left, generated_left)
    _ => generated_left
  }
  let (right, right_scale) = match operation {
    Divide | DivideInteger | Remainder => (exact_divisor(profile), 0)
    Power => ({ coefficient: 2N, scale: 0 }, 0)
    Quantize => ({ coefficient: 1N, scale: left.scale }, left.scale)
    Rescale =>
      ({ coefficient: @bigint.BigInt::from_int(-left.scale), scale: 0 }, 0)
    ScaleB => ({ coefficient: 0N, scale: 0 }, 0)
    SquareRoot
    | Plus
    | Minus
    | Abs
    | Reduce
    | ToIntegralExact
    | ToIntegralValue => ({ coefficient: 0N, scale: 0 }, 0)
    _ =>
      (
        parse_decimal_value(
          generate_decimal(
            seed + 97,
            digits,
            generated_right_scale,
            seed % 5 == 0,
          ),
        ),
        generated_right_scale,
      )
  }
  let third = if operation is Fma {
    parse_decimal_value(
      generate_decimal(seed + 193, digits, left_scale, seed % 7 == 0),
    )
  } else {
    { coefficient: 0N, scale: 0 }
  }
  {
    left,
    right,
    third,
    operation,
    timing_scope,
    digits,
    left_scale,
    right_scale,
  }
}

///|
fn dataset_profile(digit_scales : Array[Int], dataset_id : Int) -> Int {
  let digits = digit_scales[dataset_id]
  let mut profile = 0
  for prior_id in 0..<dataset_id {
    if digit_scales[prior_id] == digits {
      profile = profile + 1
    }
  }
  profile
}

///|
fn mare_input_text(input : MareDecimalInput) -> String {
  operation_name(input.operation) +
  "|" +
  input.digits.to_string() +
  "|" +
  canonical_string(input.left) +
  "|" +
  canonical_string(input.right) +
  "|" +
  canonical_string(input.third)
}

///|
fn observation_token(observation : DecimalObservation) -> Int {
  match observation {
    Dz(value) =>
      if value.is_zero() {
        0
      } else if value.negative {
        -1
      } else {
        1
      }
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
  timing_scope : TimingScope,
  digit_scales : Array[Int],
) -> @mare_fixture.Fixture[Int, MareDecimalInput, DecimalFixture] {
  @mare_fixture.Fixture::new(
    "dzmingli-vs-floating-gda",
    "decimal-neutral-v1",
    context => {
      materialize_mare_input(operation, timing_scope, digit_scales, context)
    },
    input => @mare_generator.stable_fingerprint(mare_input_text(input)),
    input => input,
    (input, _, _) => {
      prepare_fixture3(input.operation, input.left, input.right, input.third)
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
    "decimal-bigint-exact-finite-v1",
    () => (),
    _ => 1,
    (input, _, context) => {
      @mare_model.OperationResult::completed(
        oracle_operation3(operation, input.left, input.right, input.third).value,
        context,
      )
    },
    (_, _, expected, actual) => validation_status(expected, actual),
    canonical_string,
  )
}

///|
fn run_dz_for_scope(
  fixture : DecimalFixture,
  timing_scope : TimingScope,
) -> DecimalObservation {
  match timing_scope {
    OperationOnly => run_dz(fixture)
    FullPath => run_dz_full(fixture)
  }
}

///|
fn run_gda_for_scope(
  fixture : DecimalFixture,
  timing_scope : TimingScope,
) -> DecimalObservation {
  match timing_scope {
    OperationOnly => run_gda(fixture)
    FullPath => run_gda_full(fixture)
  }
}

///|
fn mare_case(
  operation : Operation,
  timing_scope : TimingScope,
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
  let dz_implementation = @mare_runner.Implementation::in_process(
    "dzmingli_decimal",
    "DzmingLi/decimal@0.2.2",
    () => (),
    (prepared, context) => {
      @mare_model.OperationResult::completed(
        run_dz_for_scope(prepared, timing_scope),
        context,
      )
    },
  )
  let gda_implementation = @mare_runner.Implementation::in_process(
    "floating_decimal_gda",
    "Luna-Flow/floating@0.6.1",
    () => (),
    (prepared, context) => {
      @mare_model.OperationResult::completed(
        run_gda_for_scope(prepared, timing_scope),
        context,
      )
    },
  )
  @mare_runner.BenchSpec::advanced(
    "decimal_" +
    operation_name(operation) +
    "_" +
    timing_scope_name(timing_scope),
    mare_fixture(operation, timing_scope, digit_scales),
    [dz_implementation, gda_implementation],
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
        [
          canonical_string(input.left),
          canonical_string(input.right),
          canonical_string(input.third),
        ],
        "exact_finite",
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
        "src/dzmingli_vs_floating/bench",
        "--target",
        "native",
        "--",
        operation_name(input.operation),
        timing_scope_name(input.timing_scope),
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
      "decimal-exact-finite-v1",
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
      "dzmingli-vs-floating-gda",
    ),
  )
}

///|
fn decision_name(decision : @mare_stats.Decision) -> String {
  match decision {
    Faster => "gda_faster"
    Slower => "dzmingli_faster"
    Equivalent => "equivalent"
    Invalid => "invalid"
    Unknown => "unknown"
  }
}

///|
fn performance_results(
  operation : Operation,
  timing_scope : TimingScope,
  digit_scales : Array[Int],
  observations : Array[@mare_model.Observation],
  validations : Array[@mare_model.Validation],
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
    let correctness_valid = correctness_valid_for_digits(digits, validations)
    let (paired_dz_samples, paired_gda_samples) = paired_samples_for_digits(
      digits, digit_scales, observations,
    )
    let dz_samples = if correctness_valid {
      paired_dz_samples
    } else {
      samples_for_digits("dzmingli_decimal", digits, digit_scales, observations)
    }
    let gda_samples = if correctness_valid {
      paired_gda_samples
    } else {
      samples_for_digits(
        "floating_decimal_gda", digits, digit_scales, observations,
      )
    }
    let dz_stats = @mare_stats.summarize(dz_samples)
    let gda_stats = @mare_stats.summarize(gda_samples)
    let comparison = if correctness_valid {
      Some(
        @mare_stats.compare_paired(
          "dzmingli_decimal",
          "floating_decimal_gda",
          dz_samples,
          gda_samples,
          3.0,
          @mare_model.confirmatory_interval(),
        ),
      )
    } else {
      None
    }
    results.push({
      operation,
      timing_scope,
      digits,
      correctness_valid,
      dz_median_us: dz_stats.median,
      gda_median_us: gda_stats.median,
      gda_relative_delta_pct: match comparison {
        Some(comparison) => comparison.relative_delta_pct
        None => 0.0
      },
      dz_speedup_vs_gda: if !correctness_valid || dz_stats.median == 0.0 {
        0.0
      } else {
        gda_stats.median / dz_stats.median
      },
      decision: match comparison {
        Some(comparison) => decision_name(comparison.decision)
        None => "invalid_correctness"
      },
      samples: match comparison {
        Some(comparison) => comparison.valid_samples
        None => gda_samples.length()
      },
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
  let dz_samples = []
  let gda_samples = []
  for baseline in observations {
    if baseline.implementation_id != "dzmingli_decimal" ||
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
        dz_samples.push(baseline.raw_elapsed_us)
        gda_samples.push(candidate.raw_elapsed_us)
        break
      }
    }
  }
  (dz_samples, gda_samples)
}

///|
fn samples_for_digits(
  implementation_id : String,
  digits : Int,
  digit_scales : Array[Int],
  observations : Array[@mare_model.Observation],
) -> Array[Double] {
  let samples = []
  for observation in observations {
    if observation.implementation_id == implementation_id &&
      observation.phase.text() == "confirmatory" &&
      observation.valid &&
      digit_scales[observation.dataset_id] == digits {
      samples.push(observation.raw_elapsed_us)
    }
  }
  samples
}

///|
fn correctness_valid_for_digits(
  digits : Int,
  validations : Array[@mare_model.Validation],
) -> Bool {
  let scale_text = digits.to_string()
  let mut dz_valid = false
  let mut gda_valid = false
  for validation in validations {
    if validation.scale_text != scale_text {
      continue
    }
    match validation.status {
      @mare_model.ValidationStatus::Valid =>
        if validation.implementation_id == "dzmingli_decimal" {
          dz_valid = true
        } else if validation.implementation_id == "floating_decimal_gda" {
          gda_valid = true
        }
      _ => return false
    }
  }
  dz_valid && gda_valid
}

///|
pub async fn run_mare_benchmark(
  operations : Array[Operation],
  timing_scope : TimingScope,
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
    let plan = mare_case(operation, timing_scope, digit_scales)
      .compile()
      .unwrap()
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
        timing_scope,
        digit_scales,
        memory.observations,
        memory.validations,
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

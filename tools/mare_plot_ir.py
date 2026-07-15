"""Parse Mare Mark JSONL into a small, reusable Plot IR model.

The parser is deliberately package-agnostic: both ``decimal_*`` (the
DzmingLi benchmark) and ``x_*`` (the moonbit/x benchmark) cases are accepted,
while timing scopes and implementation names remain data-driven.
"""

from __future__ import annotations

import json
import statistics
from collections import defaultdict
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any


ARTIFACT_VERSION = "mmka_1"
SCHEMA_VERSION = "mmks_1"
SCOPE_ALIASES = {
    "arithmetic_only": "arithmetic_only",
    "full_path": "full_path",
    "semantic_equivalent_pipeline": "semantic_equivalent_pipeline",
    "exact_overlap": "arithmetic_only",
    "x_compatible": "semantic_equivalent_pipeline",
}


@dataclass(frozen=True)
class PlotPoint:
    x: str
    y: float
    series: str


@dataclass(frozen=True)
class Plot:
    kind: str
    title: str
    unit: str
    interval_kind: str
    points: tuple[PlotPoint, ...]


@dataclass(frozen=True)
class CorpusSummary:
    total: int
    passed: int
    failed: int
    unsupported: int
    expected_difference: int


@dataclass(frozen=True)
class DifferentialReport:
    mismatches: tuple[object, ...]
    capabilities: tuple[object, ...]
    counterexamples: tuple[object, ...]
    corpus: CorpusSummary


@dataclass(frozen=True)
class PlotDocument:
    schema_version: str
    run_id: str
    target: str
    plots: tuple[Plot, ...]
    differential: DifferentialReport

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)

    def write_json(self, path: Path) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(
            json.dumps(self.to_dict(), ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )


def parse_case(case: str) -> tuple[str, str]:
    if not isinstance(case, str) or "_" not in case:
        raise ValueError(f"unexpected benchmark case: {case}")
    body = case.split("_", 1)[1]
    for suffix, scope in sorted(SCOPE_ALIASES.items(), key=lambda item: -len(item[0])):
        marker = f"_{suffix}"
        if body.endswith(marker):
            return body[: -len(marker)], scope
    raise ValueError(f"case has no recognized scope: {case}")


def _validate_artifact_version(record: dict[str, Any], line_number: int) -> None:
    version = record.get("artifact_version")
    if version != ARTIFACT_VERSION:
        raise ValueError(
            f"unsupported artifact version {version!r} at line {line_number}"
        )


def _plot_title(operation: str, scope: str) -> str:
    return f"{scope} · {operation} · median latency"


def find_scaling_plot(
    document: PlotDocument, operation: str, scope: str
) -> Plot | None:
    title = _plot_title(operation, scope)
    return next((plot for plot in document.plots if plot.title == title), None)


def load_plot_document(path: Path | str) -> PlotDocument:
    path = Path(path)
    current_validation: dict[tuple[str, int, str], tuple[int, bool]] = {}
    observations: defaultdict[
        tuple[str, str, int, str], list[float]
    ] = defaultdict(list)
    plot_order: list[tuple[str, str]] = []
    run_id = path.stem
    target = "unknown"
    corpus = CorpusSummary(0, 0, 0, 0, 0)

    with path.open(encoding="utf-8") as source:
        for line_number, line in enumerate(source, start=1):
            if not line.strip():
                continue
            record = json.loads(line)
            if not isinstance(record, dict):
                raise ValueError(f"JSONL event at line {line_number} is not an object")
            _validate_artifact_version(record, line_number)
            record_type = record.get("type")
            if record_type in {"validation", "validation_failure"}:
                operation, scope = parse_case(record["case"])
                key = (
                    record["implementation"],
                    record["dataset_id"],
                    record["case"],
                )
                current_validation[key] = (
                    int(record["scale"]),
                    record_type == "validation" and record.get("status") == "valid",
                )
                if (operation, scope) not in plot_order:
                    plot_order.append((operation, scope))
            elif record_type == "observation" and record.get("phase") == "confirmatory":
                operation, scope = parse_case(record["case"])
                validation_key = (
                    record["implementation"],
                    record["dataset_id"],
                    record["case"],
                )
                if validation_key not in current_validation:
                    raise ValueError(f"observation precedes validation: {validation_key}")
                scale, valid = current_validation[validation_key]
                if valid and record.get("valid", True):
                    observation_key = (
                        operation,
                        scope,
                        scale,
                        record["implementation"],
                    )
                    observations[observation_key].append(float(record["elapsed_us"]))
            elif record_type == "comparison":
                # Comparisons are retained as a regular speedup plot. This
                # avoids recomputing ratios from rounded medians.
                operation = str(record["operation"])
                scope = str(record["timing_scope"])
                if ("__speedup__", scope) not in plot_order:
                    plot_order.append(("__speedup__", scope))
                observations[("__speedup__", scope, int(record["digits"]), operation)].append(
                    float(record.get("dz_speedup_vs_gda", record.get("x_speedup_vs_gda", 0.0)))
                )
            elif record_type == "summary":
                environment = record.get("environment", {})
                semantic = environment.get("semantic", {})
                provenance = environment.get("provenance", {})
                target = semantic.get("target", target)
                run_id = provenance.get("run_id", run_id)
                corpus = CorpusSummary(
                    corpus.total + int(record.get("validation_count", 0)),
                    corpus.passed + int(record.get("passed_count", 0)),
                    corpus.failed + int(record.get("failed_count", 0)),
                    corpus.unsupported + int(record.get("unsupported_count", 0)),
                    corpus.expected_difference
                    + int(record.get("expected_difference_count", 0)),
                )

    plots = []
    for operation, scope in plot_order:
        if operation == "__speedup__":
            grouped: dict[tuple[int, str], list[float]] = defaultdict(list)
            for (candidate_operation, candidate_scope, scale, implementation), values in observations.items():
                if candidate_operation == operation and candidate_scope == scope:
                    grouped[(scale, implementation)].extend(values)
            points = [
                PlotPoint(str(scale), statistics.median(values), implementation)
                for (scale, implementation), values in grouped.items()
            ]
            points.sort(key=lambda point: (point.series, int(point.x)))
            if points:
                plots.append(Plot("scaling", f"{scope} · speedup versus GDA", "×", "median", tuple(points)))
            continue
        points = [
            PlotPoint(str(scale), statistics.median(values), implementation)
            for (
                candidate_operation,
                candidate_scope,
                scale,
                implementation,
            ), values in observations.items()
            if candidate_operation == operation and candidate_scope == scope
        ]
        points.sort(key=lambda point: (point.series, int(point.x)))
        if points:
            plots.append(
                Plot(
                    kind="scaling",
                    title=_plot_title(operation, scope),
                    unit="µs/op",
                    interval_kind="median",
                    points=tuple(points),
                )
            )

    return PlotDocument(
        schema_version=SCHEMA_VERSION,
        run_id=run_id,
        target=target,
        plots=tuple(plots),
        differential=DifferentialReport((), (), (), corpus),
    )

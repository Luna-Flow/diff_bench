#!/usr/bin/env python3
"""Professional layout for the moonbit/x Decimal versus GDA benchmark."""

from __future__ import annotations

import argparse
from pathlib import Path

from mare_plot_ir import PlotDocument, find_scaling_plot, load_plot_document

OPERATIONS = ("add", "subtract", "multiply", "divide", "compare")
SCOPES = ("arithmetic_only", "semantic_equivalent_pipeline")
LABELS = {
    "add": "Addition", "subtract": "Subtraction", "multiply": "Multiplication",
    "divide": "Division", "compare": "Comparison",
    "arithmetic_only": "Operation only", "semantic_equivalent_pipeline": "Semantic pipeline",
    "x_decimal": "moonbit/x Decimal", "floating_decimal_gda": "floating GDA",
}
COLORS = {"floating_decimal_gda": "#1D4ED8", "x_decimal": "#D97706"}
MARKERS = {"floating_decimal_gda": "o", "x_decimal": "s"}


def render(document: PlotDocument, output_stem: Path) -> None:
    import matplotlib.pyplot as plt
    from matplotlib.lines import Line2D
    from matplotlib.ticker import FuncFormatter, LogLocator

    plt.rcParams.update({"font.family": "sans-serif", "font.size": 8.5,
                         "axes.titlesize": 10, "axes.labelsize": 9,
                         "axes.linewidth": 0.7, "pdf.fonttype": 42,
                         "ps.fonttype": 42})
    figure = plt.figure(figsize=(12.4, 6.4))
    grid = figure.add_gridspec(2, 10)
    panels = [
        ("arithmetic_only", operation, grid[0, index * 2:(index + 1) * 2])
        for index, operation in enumerate(OPERATIONS)
    ] + [
        ("semantic_equivalent_pipeline", "multiply", grid[1, 2:5]),
        ("semantic_equivalent_pipeline", "divide", grid[1, 5:8]),
    ]
    axes = []
    for scope, operation, slot in panels:
        axis = figure.add_subplot(slot, sharey=axes[0] if axes else None)
        axes.append(axis)
        plot = find_scaling_plot(document, operation, scope)
        series_names = tuple(dict.fromkeys(point.series for point in (plot.points if plot else ())))
        for implementation in series_names:
            points = sorted(
                (int(point.x), point.y)
                for point in plot.points
                if point.series == implementation
            )
            if points:
                axis.plot(
                    [x for x, _ in points],
                    [y for _, y in points],
                    color=COLORS[implementation],
                    marker=MARKERS[implementation],
                    markersize=3.8,
                    linewidth=1.3,
                )
        axis.set_xscale("log", base=2)
        axis.set_yscale("log")
        axis.set_xlim(0.8, 5000)
        axis.grid(True, which="major", color="#CBD5E1", linewidth=.45)
        axis.grid(True, which="minor", axis="y", color="#E2E8F0", linewidth=.3)
        axis.spines[["top", "right"]].set_visible(False)
        title = LABELS[operation]
        if scope == "semantic_equivalent_pipeline":
            title = f"X-compatible {title.lower()}"
        axis.set_title(title, pad=7)
        axis.set_xlabel("Coefficient digits")
        axis.xaxis.set_major_formatter(FuncFormatter(lambda value, _: f"{value:,.0f}"))
        axis.yaxis.set_major_locator(LogLocator(base=10, numticks=7))
        if operation == "add" or (scope == "semantic_equivalent_pipeline" and operation == "multiply"):
            axis.set_ylabel(f"{LABELS[scope]}\nMedian latency (µs/op)")
    figure.suptitle("Decimal Scaling: moonbit/x versus floating GDA", x=.07, y=.985, ha="left", fontsize=15)
    figure.text(.07, .945, "Median confirmatory latency · release/native · lower is better\n"
                "Prepared operands and semantic policy are kept outside the timed path.",
                ha="left", va="top", fontsize=9, color="#475569")
    reference = find_scaling_plot(document, "add", SCOPES[0])
    series_names = tuple(dict.fromkeys(point.series for point in (reference.points if reference else ())))
    handles = [Line2D([], [], color=COLORS[name], marker=MARKERS[name],
                      linewidth=1.4, markersize=4.5,
                      label=LABELS.get(name, name.replace("_", " ").title()))
               for name in series_names]
    figure.legend(handles=handles, loc="lower center", bbox_to_anchor=(.5, .005), ncol=2, frameon=False)
    figure.subplots_adjust(left=.07, right=.99, top=.85, bottom=.15, wspace=.6, hspace=.42)
    output_stem.parent.mkdir(parents=True, exist_ok=True)
    figure.savefig(output_stem.with_suffix(".png"), dpi=240, facecolor="white")
    figure.savefig(output_stem.with_suffix(".pdf"), bbox_inches="tight", facecolor="white")
    figure.savefig(output_stem.with_suffix(".svg"), bbox_inches="tight", facecolor="white")
    plt.close(figure)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", nargs="?", type=Path, default=Path("artifacts/floating_vs_decmial_x/scaling.jsonl"))
    parser.add_argument("--output", type=Path, default=Path("artifacts/floating_vs_decmial_x/main"))
    parser.add_argument("--ir-output", type=Path, default=Path("artifacts/floating_vs_decmial_x/main.ir.json"))
    args = parser.parse_args()
    document = load_plot_document(args.input)
    document.write_json(args.ir_output)
    render(document, args.output)


if __name__ == "__main__":
    main()

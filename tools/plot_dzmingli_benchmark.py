#!/usr/bin/env python3
"""Render the final DzmingLi versus floating GDA benchmark figure."""

from __future__ import annotations

import argparse
from pathlib import Path

from mare_plot_ir import PlotDocument, find_scaling_plot, load_plot_document


IMPLEMENTATIONS = ("floating_decimal_gda", "dzmingli_decimal")
OPERATIONS = ("add", "subtract", "multiply", "divide", "compare")
SCOPES = ("arithmetic_only", "full_path")
LABELS = {
    "floating_decimal_gda": "floating GDA",
    "dzmingli_decimal": "DzmingLi decimal",
    "add": "Addition",
    "subtract": "Subtraction",
    "multiply": "Multiplication",
    "divide": "Exact division",
    "compare": "Comparison",
    "arithmetic_only": "Arithmetic only",
    "full_path": "Full path",
}
COLORS = {"floating_decimal_gda": "#006BA4", "dzmingli_decimal": "#E07A1F"}
MARKERS = {"floating_decimal_gda": "o", "dzmingli_decimal": "s"}
INVALID_FROM = 4096
ABORT_FROM = 32768


def digit_label(value: float, _position: float) -> str:
    return f"{value:,.0f}"


def render(document: PlotDocument, output_stem: Path) -> None:
    import matplotlib.pyplot as plt
    from matplotlib.lines import Line2D
    from matplotlib.patches import Patch
    from matplotlib.ticker import FuncFormatter, LogLocator

    plt.rcParams.update(
        {
            "font.family": "sans-serif",
            "font.size": 8.5,
            "axes.titlesize": 10,
            "axes.labelsize": 9,
            "legend.fontsize": 8.5,
            "xtick.labelsize": 7.5,
            "ytick.labelsize": 7.5,
            "axes.linewidth": 0.7,
            "pdf.fonttype": 42,
            "ps.fonttype": 42,
        }
    )
    figure, axes = plt.subplots(2, 5, figsize=(12.4, 5.8), sharex=True, sharey=True)
    x_max = 24000

    for row, scope in enumerate(SCOPES):
        for column, operation in enumerate(OPERATIONS):
            axis = axes[row, column]
            if operation != "compare":
                axis.axvspan(INVALID_FROM, x_max, color="#D6D6D6", alpha=0.62, zorder=0)
                axis.axvline(INVALID_FROM, color="#777777", linewidth=0.8, linestyle=(0, (3, 2)), zorder=1)
                if row == 0:
                    axis.text(
                        0.98,
                        0.96,
                        "DzmingLi invalid\n≥ 4,096 digits",
                        transform=axis.transAxes,
                        ha="right",
                        va="top",
                        color="#555555",
                        fontsize=7.3,
                    )

            for implementation in IMPLEMENTATIONS:
                plot = find_scaling_plot(document, operation, scope)
                points = [] if plot is None else sorted(
                    (int(point.x), point.y)
                    for point in plot.points
                    if point.series == implementation
                )
                if not points:
                    continue
                axis.plot(
                    [point[0] for point in points],
                    [point[1] for point in points],
                    color=COLORS[implementation],
                    marker=MARKERS[implementation],
                    markersize=3.8,
                    markeredgewidth=0.5,
                    linewidth=1.35,
                    label=LABELS[implementation],
                    zorder=3,
                )

            axis.set_xscale("log", base=2)
            axis.set_yscale("log")
            axis.set_xlim(0.8, x_max)
            axis.grid(True, which="major", color="#C8C8C8", linewidth=0.45, alpha=0.65)
            axis.grid(True, which="minor", axis="y", color="#E2E2E2", linewidth=0.35, alpha=0.55)
            axis.spines[["top", "right"]].set_visible(False)
            axis.set_title(LABELS[operation], pad=7)
            axis.xaxis.set_major_formatter(FuncFormatter(digit_label))
            axis.yaxis.set_major_locator(LogLocator(base=10, numticks=7))
            if column == 0:
                axis.set_ylabel(f"{LABELS[scope]}\nMedian latency (µs/op)", labelpad=6)
            if row == 1:
                axis.set_xlabel("Coefficient digits")

    figure.suptitle(
        "Scaling of Decimal Arithmetic: floating GDA versus DzmingLi",
        x=0.07,
        y=0.985,
        ha="left",
        fontsize=15,
    )
    figure.text(
        0.07,
        0.945,
        "Median confirmatory latency on Apple M4 · release/native · lower is better · invalid results excluded\n"
        "DzmingLi aborts at ≥32,768-digit stress inputs; comparison remains valid through 20,000 digits.",
        ha="left",
        va="top",
        fontsize=9,
        color="#555555",
    )
    legend_handles = [
        Line2D([], [], color=COLORS[implementation], marker=MARKERS[implementation], linewidth=1.5, markersize=4.5, label=LABELS[implementation])
        for implementation in IMPLEMENTATIONS
    ] + [Patch(facecolor="#D6D6D6", edgecolor="none", label="DzmingLi arithmetic incorrect (≥ 4,096 digits)")]
    figure.legend(handles=legend_handles, loc="lower center", bbox_to_anchor=(0.5, 0.005), ncol=3, frameon=False)
    figure.subplots_adjust(left=0.07, right=0.99, top=0.84, bottom=0.16, wspace=0.16, hspace=0.27)

    output_stem.parent.mkdir(parents=True, exist_ok=True)
    figure.savefig(output_stem.with_suffix(".png"), dpi=240, facecolor="white")
    figure.savefig(output_stem.with_suffix(".pdf"), bbox_inches="tight", facecolor="white")
    figure.savefig(output_stem.with_suffix(".svg"), bbox_inches="tight", facecolor="white")
    plt.close(figure)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "input",
        nargs="?",
        type=Path,
        default=Path("artifacts/dzmingli_vs_floating/scaling.jsonl"),
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("artifacts/dzmingli_vs_floating/main"),
        help="output path without an extension",
    )
    parser.add_argument("--ir-output", type=Path,
                        default=Path("artifacts/dzmingli_vs_floating/main.ir.json"),
                        help="mare_mark mmks_1 Plot IR JSON output")
    arguments = parser.parse_args()
    document = load_plot_document(arguments.input)
    document.write_json(arguments.ir_output)
    render(document, arguments.output)


if __name__ == "__main__":
    main()

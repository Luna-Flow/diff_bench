#!/usr/bin/env python3
"""Render supplementary operation scaling for the DzmingLi comparison."""

from __future__ import annotations

import argparse
from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
from matplotlib.ticker import FuncFormatter, LogLocator

from plot_dzmingli_benchmark import COLORS, LABELS, MARKERS, load_results


ARITHMETIC_OPERATIONS = (
    "abs",
    "minus",
    "plus",
    "fma",
    "power",
    "sqrt",
    "remainder",
    "divide_integer",
)
TRANSFORM_OPERATIONS = (
    "quantize",
    "rescale",
    "reduce",
    "scaleb",
    "to_integral_exact",
    "to_integral_value",
)
OPERATION_LABELS = {
    "abs": "Absolute value",
    "minus": "Unary minus",
    "plus": "Unary plus",
    "fma": "Fused multiply–add",
    "power": "Power",
    "sqrt": "Square root",
    "remainder": "Remainder",
    "divide_integer": "Integer division",
    "quantize": "Quantize",
    "rescale": "Rescale",
    "reduce": "Reduce",
    "scaleb": "ScaleB",
    "to_integral_exact": "To-integral exact",
    "to_integral_value": "To-integral value",
}
SCOPES = ("arithmetic_only", "full_path")
LINESTYLES = {"arithmetic_only": "-", "full_path": (0, (4, 2))}


def digit_label(value: float, _position: float) -> str:
    return f"{value:,.0f}"


def render(results, output_stem: Path) -> None:
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
    figure, axes = plt.subplots(4, 4, figsize=(12.4, 9.2), sharex=True, sharey=True)
    operations = ARITHMETIC_OPERATIONS + TRANSFORM_OPERATIONS

    for index, operation in enumerate(operations):
        axis = axes.flat[index]
        for implementation in COLORS:
            for scope in SCOPES:
                points = sorted(
                    (scale, latency)
                    for (op, timing_scope, scale, impl), latency in results.items()
                    if op == operation and timing_scope == scope and impl == implementation
                )
                if points:
                    axis.plot(
                        [point[0] for point in points],
                        [point[1] for point in points],
                        color=COLORS[implementation],
                        marker=MARKERS[implementation],
                        markersize=3.4,
                        markeredgewidth=0.45,
                        linewidth=1.2,
                        linestyle=LINESTYLES[scope],
                        zorder=3,
                    )

        axis.set_xscale("log", base=2)
        axis.set_yscale("log")
        axis.set_xlim(0.8, 1250)
        axis.grid(True, which="major", color="#C8C8C8", linewidth=0.45, alpha=0.65)
        axis.grid(True, which="minor", axis="y", color="#E2E2E2", linewidth=0.35, alpha=0.55)
        axis.spines[["top", "right"]].set_visible(False)
        axis.set_title(OPERATION_LABELS[operation], pad=6)
        axis.xaxis.set_major_formatter(FuncFormatter(digit_label))
        axis.yaxis.set_major_locator(LogLocator(base=10, numticks=7))
        if index % 4 == 0:
            axis.set_ylabel("Median latency (µs/op)")
        if index // 4 == 3:
            axis.set_xlabel("Coefficient digits")

        category = "Other arithmetic" if operation in ARITHMETIC_OPERATIONS else "Decimal transforms"
        axis.text(
            0.02,
            0.96,
            category,
            transform=axis.transAxes,
            ha="left",
            va="top",
            fontsize=7.2,
            color="#666666",
        )

    for index in range(len(operations), len(axes.flat)):
        axes.flat[index].set_visible(False)

    figure.suptitle(
        "Supplementary Scaling: Arithmetic and Decimal Transformations",
        x=0.07,
        y=0.985,
        ha="left",
        fontsize=15,
    )
    figure.text(
        0.07,
        0.951,
        "floating GDA versus DzmingLi · median confirmatory latency on Apple M4 · release/native · lower is better\n"
        "All displayed oracle validations pass; the extended corpus covers these operations through 1,024 coefficient digits.",
        ha="left",
        va="top",
        fontsize=9,
        color="#555555",
    )
    legend_handles = [
        Line2D([], [], color=COLORS[implementation], marker=MARKERS[implementation], linewidth=1.4, markersize=4.5, label=LABELS[implementation])
        for implementation in COLORS
    ] + [
        Line2D([], [], color="#555555", linewidth=1.4, linestyle=LINESTYLES[scope], label=LABELS[scope])
        for scope in SCOPES
    ]
    figure.legend(handles=legend_handles, loc="lower center", bbox_to_anchor=(0.5, 0.006), ncol=4, frameon=False)
    figure.subplots_adjust(left=0.07, right=0.99, top=0.87, bottom=0.10, wspace=0.17, hspace=0.31)

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
        default=Path("artifacts/mare_mark_dzmingli_vs_floating_extended.jsonl"),
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("artifacts/dzmingli_vs_floating_supplementary_benchmark"),
        help="output path without an extension",
    )
    arguments = parser.parse_args()
    render(load_results(arguments.input), arguments.output)


if __name__ == "__main__":
    main()

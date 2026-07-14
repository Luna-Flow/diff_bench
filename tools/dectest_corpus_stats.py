#!/usr/bin/env python3
import json
import re
import shlex
import sys
from pathlib import Path


TARGET_OPERATIONS = {
    "abs",
    "add",
    "apply",
    "compare",
    "divide",
    "divideint",
    "exp",
    "fma",
    "ln",
    "log10",
    "minus",
    "multiply",
    "plus",
    "power",
    "quantize",
    "reduce",
    "remainder",
    "rescale",
    "scaleb",
    "squareroot",
    "subtract",
    "tointegral",
    "tointegralx",
    "tosci",
}


def strip_comment(line: str) -> str:
    quote = ""
    index = 0
    while index < len(line):
        character = line[index]
        if quote:
            if character == quote:
                quote = ""
        elif character in "'\"":
            quote = character
        elif line[index : index + 2] == "--":
            return line[:index]
        index += 1
    return line


def decimal_size(token: str) -> tuple[int, int]:
    match = re.fullmatch(
        r"[+-]?(?P<mantissa>(?:\d+(?:\.\d*)?|\.\d+))(?:[eE](?P<exponent>[+-]?\d+))?",
        token,
    )
    if match is None:
        return (0, 0)
    digits = sum(character.isdigit() for character in match.group("mantissa"))
    exponent = abs(int(match.group("exponent") or "0"))
    return (digits, exponent)


def summarize(paths: list[Path]) -> dict[str, object]:
    operation_counts = {operation: 0 for operation in sorted(TARGET_OPERATIONS)}
    total_cases = 0
    target_cases = 0
    max_operand_digits = 0
    max_result_digits = 0
    max_exp_magnitude = 0
    source_bytes = 0
    for path in paths:
        source_bytes += path.stat().st_size
        for raw_line in path.read_text(encoding="utf-8").splitlines():
            line = strip_comment(raw_line).strip()
            if "->" not in line:
                continue
            left, right = line.split("->", 1)
            try:
                left_tokens = shlex.split(left)
                right_tokens = shlex.split(right)
            except ValueError as error:
                raise SystemExit(f"{path}: cannot tokenize {line!r}: {error}")
            if len(left_tokens) < 3 or not right_tokens:
                continue
            total_cases += 1
            operation = left_tokens[1].lower()
            if operation not in TARGET_OPERATIONS:
                continue
            target_cases += 1
            operation_counts[operation] += 1
            for operand in left_tokens[2:]:
                digits, exponent = decimal_size(operand)
                max_operand_digits = max(max_operand_digits, digits)
                max_exp_magnitude = max(max_exp_magnitude, exponent)
            digits, exponent = decimal_size(right_tokens[0])
            max_result_digits = max(max_result_digits, digits)
            max_exp_magnitude = max(max_exp_magnitude, exponent)
    return {
        "files": len(paths),
        "source_bytes": source_bytes,
        "total_cases": total_cases,
        "target_cases": target_cases,
        "operation_counts": operation_counts,
        "max_operand_coefficient_digits": max_operand_digits,
        "max_result_coefficient_digits": max_result_digits,
        "max_exp_magnitude": max_exp_magnitude,
    }


def main() -> None:
    paths = [Path(argument) for argument in sys.argv[1:]]
    if not paths:
        raise SystemExit("usage: dectest_corpus_stats.py FILE.decTest [...]")
    missing = [str(path) for path in paths if not path.is_file()]
    if missing:
        raise SystemExit("missing decTest files: " + ", ".join(missing))
    print(json.dumps(summarize(paths), indent=2, sort_keys=True))


if __name__ == "__main__":
    main()

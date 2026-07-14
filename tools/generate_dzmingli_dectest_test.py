#!/usr/bin/env python3
import sys
from pathlib import Path


def moonbit_multiline(source: str) -> str:
    return "\n".join("  #|" + line for line in source.splitlines())


def generate_case(path: Path) -> str:
    source = moonbit_multiline(path.read_text(encoding="utf-8"))
    return f'''///|
test "official GDA {path.name}" {{
  let source : String =
{source}
  let cases = @dectest.parse_dectest(source)
  let selected = []
  for case in cases {{
    if case.op == "abs" ||
      case.op == "add" ||
      case.op == "subtract" ||
      case.op == "multiply" ||
      case.op == "divide" ||
      case.op == "divideInt" ||
      case.op == "divideint" ||
      case.op == "exp" ||
      case.op == "fma" ||
      case.op == "ln" ||
      case.op == "log10" ||
      case.op == "minus" ||
      case.op == "plus" ||
      case.op == "power" ||
      case.op == "quantize" ||
      case.op == "reduce" ||
      case.op == "remainder" ||
      case.op == "rescale" ||
      case.op == "scaleB" ||
      case.op == "scaleb" ||
      case.op == "squareRoot" ||
      case.op == "squareroot" ||
      case.op == "toIntegral" ||
      case.op == "tointegral" ||
      case.op == "toIntegralX" ||
      case.op == "tointegralx" ||
      case.op == "compare" ||
      case.op == "toSci" ||
      case.op == "tosci" ||
      case.op == "apply" {{
      selected.push(case)
    }}
  }}
  let (failures, skipped) = @dectest.run_cases_with_flags(selected)
  if failures.length() > 0 {{
    let limit = Int::min(failures.length(), 30)
    for index in 0..<limit {{
      println(failures[index])
    }}
  }}
  println("{path.name}: \\{{selected.length()}} selected")
  inspect(failures.length(), content="0")
  inspect(skipped, content="0")
}}
'''


def main() -> None:
    if len(sys.argv) < 3:
        raise SystemExit(
            "usage: generate_dzmingli_dectest_test.py OUTPUT FILE.decTest [...]"
        )
    output = Path(sys.argv[1])
    paths = [Path(argument) for argument in sys.argv[2:]]
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(generate_case(path) for path in paths), encoding="utf-8")


if __name__ == "__main__":
    main()

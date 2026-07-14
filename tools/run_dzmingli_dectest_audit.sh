#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CACHE=${TMPDIR:-/tmp}/diff-bench-dectest-audit
CORPUS_DIR=$CACHE/official
ARCHIVE=$CACHE/dectest.zip
DZ_REPO=$CACHE/decimal
EXPECTED_SHA=b70a224cd52e82b7a8150aedac5efa2d0cb3941696fd829bdbe674f9f65c3926
DZ_COMMIT=ddae99174515bc131ab4ef05664c0cd790722ed8

mkdir -p "$CACHE"
if [ ! -f "$ARCHIVE" ]; then
  curl -L --fail --silent --show-error \
    -o "$ARCHIVE" https://speleotrove.com/decimal/dectest.zip
fi
ACTUAL_SHA=$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')
if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
  echo "decTest SHA-256 mismatch: $ACTUAL_SHA" >&2
  exit 1
fi
if [ ! -d "$CORPUS_DIR" ]; then
  mkdir -p "$CORPUS_DIR"
  unzip -q "$ARCHIVE" -d "$CORPUS_DIR"
fi

FILES="
$CORPUS_DIR/abs.decTest
$CORPUS_DIR/add.decTest
$CORPUS_DIR/subtract.decTest
$CORPUS_DIR/multiply.decTest
$CORPUS_DIR/divide.decTest
$CORPUS_DIR/divideint.decTest
$CORPUS_DIR/exp.decTest
$CORPUS_DIR/fma.decTest
$CORPUS_DIR/ln.decTest
$CORPUS_DIR/log10.decTest
$CORPUS_DIR/minus.decTest
$CORPUS_DIR/compare.decTest
$CORPUS_DIR/plus.decTest
$CORPUS_DIR/power.decTest
$CORPUS_DIR/quantize.decTest
$CORPUS_DIR/reduce.decTest
$CORPUS_DIR/remainder.decTest
$CORPUS_DIR/rescale.decTest
$CORPUS_DIR/scaleb.decTest
$CORPUS_DIR/squareroot.decTest
$CORPUS_DIR/tointegral.decTest
$CORPUS_DIR/tointegralx.decTest
$CORPUS_DIR/base.decTest
"

echo "Official GDA corpus statistics"
# Intentional word splitting turns the newline-delimited file list into arguments.
# shellcheck disable=SC2086
python3 "$ROOT/tools/dectest_corpus_stats.py" $FILES

echo "floating/decimal_gda official decTest"
(
  cd "$ROOT/.mooncakes/Luna-Flow/floating"
  # shellcheck disable=SC2086
  moon run --release src/cli --target native -- \
    --backend gda --json --strict-supported $FILES
)

if [ ! -d "$DZ_REPO/.git" ]; then
  git clone --quiet https://github.com/moonbit-community/decimal.git "$DZ_REPO"
fi
git -C "$DZ_REPO" fetch --quiet origin "$DZ_COMMIT"
git -C "$DZ_REPO" checkout --quiet --detach "$DZ_COMMIT"

for source in "$ROOT"/.mooncakes/DzmingLi/decimal/src/*.mbt; do
  name=$(basename "$source")
  if [ "$name" != "pkg.generated.mbti" ]; then
    cmp "$source" "$DZ_REPO/src/$name"
  fi
done

DZ_TEST_PACKAGE=$DZ_REPO/src/tests/diff_bench_full
mkdir -p "$DZ_TEST_PACKAGE"
cat >"$DZ_TEST_PACKAGE/moon.pkg" <<'EOF'
import {
  "moonbit-community/decimal/dectest" @dectest,
} for "test"
EOF
# Intentional word splitting turns the newline-delimited file list into arguments.
# shellcheck disable=SC2086
python3 "$ROOT/tools/generate_dzmingli_dectest_test.py" \
  "$DZ_TEST_PACKAGE/official_dectest_test.mbt" $FILES

echo "DzmingLi/decimal complete official decTest files"
(
  cd "$DZ_REPO"
  moon test src/tests/diff_bench_full
)

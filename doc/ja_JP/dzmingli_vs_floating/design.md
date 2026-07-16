# DzmingLi decimal と floating GDA の設計・性能レポート

このレポートは `Luna-Flow/floating/decimal_gda@0.7.1` の現在の benchmark run を説明します。

## 測定契約

両実装には同一の coefficient-and-scale fixture を渡します。`arithmetic_only` は公開演算だけ、
`full_path` はさらに二つの canonical 文字列の parse を計測します。検証、canonicalization、
calibration、reporting は計測外です。除算は有限小数になる除数のみを使い、両実装が独立した
exact-finite `BigInt` oracle に合格した点だけを性能比較します。

## 正当性

scaling corpus は 1,476 件を検証しました。floating GDA は 738/738 合格、DzmingLi は
630 件合格、108 件失敗です。加減乗除は coefficient 4,096 桁から失敗し、compare は
20,000 桁まで正しい結果でした。

公式 GDA 監査は 23 の arithmetic/base ファイル、合法な 17,651 行を実行し、
floating GDA はすべて合格しました。DzmingLi は全共有算術、比較、`apply` に合格しますが、active precision と rounding を
format に適用しないため `toSci` 329 行に失敗します。公式の有限 operand は最大 64 桁なので、
decTest だけでは大きな coefficient の oracle を置き換えられません。

桁数性能層は 19 の exact operation を扱い、新規 14 操作は 1,024 桁まで測定します。
`exp/ln/log10` は identity-only timing がアルゴリズムを表さず、一般結果には別の独立
transcendental oracle が必要なため decTest-only です。

DzmingLi の `digit_count` は signed `Int` で `bit_length * 30103` を計算します。
現在の native target では coefficient 約 21,475 桁から overflow の可能性があり、積・平方・
FMA・二次 power は結果桁数を倍増させるため入力約 10,738 桁から境界を越え得ます。
10,000 桁の乗算と 20,000 桁の非乗算は完走し、32,768/65,536 桁は abort しました。
これは解析・観測上の境界であり、全 operand に共通する厳密な最初の失敗点ではありません。

## 性能

1–64 桁では arithmetic-only で DzmingLi が概ね先行しますが、parse と構築を含む full-path は混在します。256 桁では両 timing scope の全 5 演算で floating GDA が先行します。双方が正しい 1,024 桁では、floating GDA は演算と scope により約 `3.54–95.44×` 高速です。より大きい算術点は DzmingLi が不正なので、GDA の検証済み latency のみを掲載し speedup は算出しません。

## 制約

Apple M4、native release、周波数制御なしの一回の測定です。fixture は三つの決定的 scale
profile、除算は小さな有限除数に限定されます。結果は回帰分析用であり一般的な順位ではありません。

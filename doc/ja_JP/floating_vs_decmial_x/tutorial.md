# 実行と再現

リポジトリルートから [api.md](api.md) のいずれかのコマンドを実行します。`MARE_CPU`、`MARE_OS`、`MARE_BUILD_MODE` などで既知の環境情報を指定できます。未指定値は `unknown` または `unspecified` です。`arithmetic_only` は直接の公開操作、`semantic_equivalent_pipeline` は X 互換の精度・切り捨て処理まで測定します。異なる MoonBit target の結果は混在させません。

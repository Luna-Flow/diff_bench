# Contribution Guidelines

他の言語版: [en_US](../en_US/CONTRIBUTING.md) | [zh_CN](../zh_CN/CONTRIBUTING.md)

## Code Style

- MoonBit コードは `just fmt` で整形します。
- まずパッケージ境界で整理し、その後に具体的な振る舞いでファイルを分けます。
- コメントは短く技術的にし、契約、不変条件、または分かりにくい実装上の判断を説明します。

## Testing

- 振る舞いを変更した場合はテストを追加または更新します。
- 必要に応じて `*_test.mbt` または `*_wbtest.mbt` を使います。
- 通常の検証には `just test`、PR 前には `just ready` を実行します。
- 公開 API を変更した場合は `just info` で interface ファイルを再生成します。

## Dependencies

- 依存関係は `just update-deps` で更新します。
- コミット前に `moon.mod` の差分を確認します。

## Release

- `moon.mod` の `version` を更新します。
- README とドキュメントが現在のパッケージ状態を反映していることを確認します。
- `just ready` を実行します。
- `publish-package` GitHub Actions workflow を手動実行し、`moon.mod` と完全に一致するバージョンを入力します。

# 贡献指南

查看其他语言版本：[en_US](../en_US/CONTRIBUTING.md) | [ja_JP](../ja_JP/CONTRIBUTING.md)

## 代码风格

- 使用 `just fmt` 格式化 MoonBit 代码。
- 优先按包边界组织文件，再按具体行为拆分。
- 注释保持简短、技术化，只解释契约、不变量或不明显的实现选择。

## 测试

- 行为变更时同步添加或更新测试。
- 根据访问需求使用包内 `*_test.mbt` 或 `*_wbtest.mbt`。
- 普通验证运行 `just test`，提交 PR 前运行 `just ready`。
- 公共 API 变化时用 `just info` 重新生成接口文件。

## 依赖

- 通过 `just update-deps` 更新依赖。
- 提交前检查 `moon.mod` diff。
- 避免在无关 PR 中修改依赖或版本声明。

## 发布

- 更新 `moon.mod` 中的 `version`。
- 确认 README 和文档反映当前包状态。
- 运行 `just ready`。
- 手动触发 `publish-package` GitHub Actions workflow，并输入与 `moon.mod` 完全一致的版本号。

# MoonModGuard 验收清单

## 仓库要求

- [x] 独立本地仓库已创建。
- [x] 项目名称、包名和申报材料一致。
- [x] `README.md` 为普通文件。
- [x] 仓库包含源码、测试、许可证、README、竞赛文档和 CI 配置。
- [x] 计划提交次数不少于 10 次。

## 功能要求

- [x] 解析 `moon.mod` 标量字段。
- [x] 解析 `keywords` 等数组字段。
- [x] 解析 `moon.mod` import 依赖。
- [x] 解析 `moon.pkg` import 依赖。
- [x] 构建项目模型并合并模块级、包级依赖。
- [x] 检查缺失 README、repository、license。
- [x] 检查非 allowlist 许可证。
- [x] 检查未知依赖前缀和重复依赖。
- [x] 输出 Markdown 审计报告。

## 可运行性

- [x] `moon info` 通过。
- [x] `moon fmt --check` 通过。
- [x] `moon test` 通过。
- [x] `moon run cmd/main` 可运行演示。

## 后续扩展

- [ ] 增加真实文件系统扫描。
- [ ] 增加工作区多包遍历。
- [ ] 输出 DOT 或 Mermaid 依赖图。
- [ ] 对接 CI 失败阈值。

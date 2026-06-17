# MoonModGuard 技术白皮书式项目申报书

## 1. 项目定位

MoonModGuard 是面向 MoonBit 生态的项目清单与供应链策略审计器。项目围绕 `moon.mod`、`moon.pkg` 等工程清单文件构建轻量审计内核，提取项目元数据、包级依赖、导入别名和发布信息，并通过策略规则生成可复查的审计报告。

GitHub 主仓库：<https://github.com/Noverberrain/MoonModGuard-MoonBit->

GitLink 镜像仓库：<https://gitlink.org.cn/Wyc060514/moonmodguard>

## 2. 问题背景

MoonBit 包生态正在增长。一个项目能否稳定发布和复现，不只取决于源码是否能编译，还取决于清单元数据是否完整、许可证是否符合策略、依赖来源是否清晰、包级导入是否可审计。当前很多检查依赖人工阅读，难以形成统一、可测试、可自动化的评审流程。

MoonModGuard 将这些工程质量要求转化为可执行规则，为包发布前检查、竞赛仓库验收、课程项目规范检查和后续 CI 集成提供基础组件。

## 3. 技术架构

系统由四个核心层组成：

1. 清单扫描层：以字符串为输入，解析 `moon.mod` 和 `moon.pkg` 中的标量字段、数组字段和 import 块。
2. 项目建模层：将 `ModuleManifest` 与多个 `PackageManifest` 合并为 `ProjectModel`。
3. 策略评估层：基于 `Policy` 检查必填元数据、许可证 allowlist、可信依赖前缀和重复依赖。
4. 报告渲染层：将 `AuditReport` 输出为稳定 Markdown，供 CLI、CI 和文档系统复用。

首版不做真实文件系统扫描，也不实现完整 MoonBit 语法解析。这个边界可以降低实现风险，并保证核心 API 易测试、易复用。

## 4. 核心模块

- `parse_mod`：解析模块级清单，提取项目名称、版本、README、仓库地址、许可证、关键词、描述和 import 依赖。
- `parse_pkg`：解析包级清单，提取包依赖和导入别名。
- `project_from`：合并模块级和包级依赖，形成项目模型。
- `evaluate_policy`：执行策略检查，生成诊断项。
- `render_markdown`：生成可读审计报告。

默认策略接受 `Apache-2.0`、`MIT`、`MulanPSL-2.0`，并将 `moonbitlang/` 和 `python123/` 作为可信依赖前缀。调用方可以提供自定义策略。

## 5. 测试与验证

项目测试覆盖以下场景：

- `moon.mod` 标量字段解析；
- `keywords` 数组字段解析；
- `moon.mod` import 依赖解析；
- `moon.pkg` import 依赖解析；
- 缺失 README、repository、license 的策略诊断；
- 非 allowlist 许可证诊断；
- 未知依赖前缀与重复依赖诊断；
- Markdown 报告稳定输出。

当前验证命令包括：

```bash
moon info
moon fmt --check
moon test
moon run cmd/main
```

## 6. 开源交付

项目以 GitHub 仓库作为官方开源发布地址，并同步保留 GitLink 仓库作为赛事平台镜像。仓库包含源码、测试、README、许可证、CI 配置、申报材料和可编辑 DOCX/PDF 交付物。

## 7. 后续计划

后续版本可扩展真实文件扫描、工作区多包遍历、依赖图可视化、CI 失败阈值和包仓库审计。首版重点交付可测试的审计内核，避免在文件系统、平台集成和网络查询上引入不必要复杂度。

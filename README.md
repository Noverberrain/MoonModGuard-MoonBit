# MoonModGuard

MoonModGuard is a MoonBit project manifest and supply-chain policy auditor.

- GitHub repository: <https://github.com/Noverberrain/MoonModGuard-MoonBit>
- GitLink mirror: <https://gitlink.org.cn/Wyc060514/moonmodguard>
- Core author: `wyc060514`
- Competition note: the GitHub repository is the primary open-source release
  link for the 2026 MoonBit domestic open-source ecosystem contest. The GitLink
  repository is kept as the contest platform mirror.

## What It Does

MoonModGuard parses `moon.mod` and `moon.pkg` text, extracts module metadata and
package imports, builds an in-memory project model, evaluates supply-chain
policy risks, and renders a deterministic Markdown audit report.

The first version is deliberately dependency-free and accepts explicit strings
or snapshots instead of scanning the filesystem. This keeps the core portable
and testable while leaving room for later CI and workspace integrations.

## Installation

```bash
moon add Noverberrain/moonmodguard
```

## Why This Exists

MoonBit projects rely on compact manifest files for package identity,
dependencies, metadata, and publication readiness. A small auditor can help
maintainers check whether a package is ready to publish, whether metadata is
complete, and whether dependency declarations match a local policy.

MoonModGuard targets software analysis and engineering quality workflows:

- package release readiness checks
- contest repository review
- classroom or team repository governance
- dependency policy demonstration
- future CI or package registry audit integration

## Features

- Parse scalar fields from `moon.mod`: `name`, `version`, `license`, `readme`,
  `repository`, `description`.
- Parse array fields such as `keywords = [ "audit", "moonbit" ]`.
- Parse import blocks from `moon.mod` and `moon.pkg`.
- Build a project model from module and package manifests.
- Evaluate policy diagnostics for missing metadata, disallowed licenses,
  unknown dependency prefixes, and duplicate dependencies.
- Render a deterministic Markdown report.
- Provide a runnable CLI demo.

## Quick Start

```bash
moon test
moon run cmd/main
```

Example CLI output:

```text
MoonModGuard demo
project=wyc060514/moonmodguard
dependencies=2
risks=0
--- markdown ---
# MoonModGuard Audit Report
```

## API Example

```mbt nocheck
///|
test "audit a project" {
  let manifest = match @moonmodguard.parse_mod(
    "name = \"wyc060514/tool\"\nlicense = \"Apache-2.0\"\nreadme = \"README.md\"\nrepository = \"https://example.test/repo\"",
  ) {
    Ok(value) => value
    Err(err) => fail(@moonmodguard.format_error(err))
  }
  let report = @moonmodguard.evaluate_policy(
    @moonmodguard.project_from(manifest, []),
    @moonmodguard.default_policy(),
  )
  assert_eq(report.risk_count, 0)
}
```

Public API:

- `parse_mod(input : String) -> Result[ModuleManifest, GuardError]`
- `parse_pkg(input : String) -> Result[PackageManifest, GuardError]`
- `project_from(manifest : ModuleManifest, packages : Array[PackageManifest]) -> ProjectModel`
- `scan_project(snapshot : ProjectSnapshot) -> AuditReport`
- `default_policy() -> Policy`
- `evaluate_policy(project : ProjectModel, policy : Policy) -> AuditReport`
- `render_markdown(report : AuditReport) -> String`
- `format_error(err : GuardError) -> String`

## Design Notes

The parser handles the common MoonBit manifest shape used by package metadata
and import declarations. It is not a full MoonBit grammar parser. That boundary
is intentional: the first release focuses on release readiness and policy audit
checks that can be validated with stable tests.

The default policy accepts `Apache-2.0`, `MIT`, and `MulanPSL-2.0`, and treats
`moonbitlang/` and `wyc060514/` as trusted dependency prefixes. Callers can pass
a custom `Policy` value for stricter project rules.

## Competition Materials

- Proposal source: `docs/competition/proposal.md`
- Submission guide: `docs/competition/submission-guide.md`
- Acceptance checklist: `docs/competition/acceptance-checklist.md`
- Application PDF: `docs/competition/MoonModGuard项目申报书.pdf`

## License

Apache-2.0

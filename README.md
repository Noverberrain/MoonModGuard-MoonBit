# python123/moonmodguard

MoonModGuard is a MoonBit project manifest and supply-chain policy auditor.

It parses `moon.mod` and `moon.pkg` text, extracts module metadata and package
imports, builds an in-memory project model, evaluates policy risks, and renders
a small Markdown audit report. The first version is deliberately dependency-free
and works on explicit strings or snapshots so it can stay portable inside the
MoonBit ecosystem.

## Why This Exists

MoonBit projects rely on compact manifest files for package identity,
dependencies, metadata, and publication readiness. A small auditor can help
maintainers check whether a package is ready to publish, whether metadata is
complete, and whether dependency declarations match a local policy.

MoonModGuard is aimed at software analysis and engineering quality workflows:

- package release readiness checks
- classroom or contest repository review
- dependency policy demonstrations
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
project=python123/moonmodguard
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
    "name = \"python123/tool\"\nlicense = \"Apache-2.0\"\nreadme = \"README.md\"\nrepository = \"https://example.test/repo\"",
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

The parser is intentionally small. It handles the common MoonBit manifest shape
used by package metadata and import declarations, not the full MoonBit grammar.
This is enough for release-readiness checks and keeps the first version easy to
test.

Policy evaluation is also explicit. The default policy accepts `Apache-2.0`,
`MIT`, and `MulanPSL-2.0`, and treats `moonbitlang/` and `python123/` as trusted
dependency prefixes. Callers can provide a different `Policy` value.

## Competition Materials

- Proposal: `docs/competition/proposal.md`
- Submission guide: `docs/competition/submission-guide.md`
- Acceptance checklist: `docs/competition/acceptance-checklist.md`
- Application PDF: `docs/competition/MoonModGuard项目申报书.pdf`

## License

Apache-2.0

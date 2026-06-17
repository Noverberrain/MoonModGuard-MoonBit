# MoonModGuard Architecture

## Positioning

MoonModGuard is a manifest and policy auditor for MoonBit projects. It does not
try to compile, execute, or fully parse MoonBit source. It focuses on package
metadata and import declarations that influence release readiness and
supply-chain review.

## Data Flow

1. Manifest text is parsed into `ModuleManifest` and `PackageManifest`.
2. Manifests are combined into a `ProjectModel`.
3. `Policy` defines required metadata, allowed licenses, and trusted dependency
   prefixes.
4. `evaluate_policy` produces an `AuditReport`.
5. `render_markdown` converts the report into human-readable output.

## Boundaries

- Inputs are strings and explicit snapshots in v1.
- No filesystem traversal is included in v1.
- No external packages are required.
- The parser supports common manifest field and import forms, not the full
  MoonBit grammar.

## Extension Points

- A filesystem scanner can later collect `moon.mod` and package `moon.pkg`
  files before calling the existing API.
- A graph renderer can later consume `ProjectModel.dependencies`.
- CI integrations can fail builds when `risk_count` exceeds a configured
  threshold.

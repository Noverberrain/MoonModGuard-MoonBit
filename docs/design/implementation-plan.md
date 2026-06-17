# MoonModGuard Implementation Plan

## Completed v1 Scope

- Parse common `moon.mod` metadata fields.
- Parse array metadata fields.
- Parse module-level and package-level import blocks.
- Build a project model from manifests.
- Evaluate default policy diagnostics.
- Render Markdown audit reports.
- Provide CLI demo and blackbox tests.

## Deferred Scope

- Real filesystem scanning.
- Full MoonBit grammar parsing.
- Dependency graph visualization.
- Registry or network lookups.
- CI exit-code mode.

## Verification

The project uses these commands as the release gate:

```bash
moon info
moon fmt --check
moon test
moon run cmd/main
```

Repository hygiene checks:

```bash
git ls-files -s README.md
git rev-list --count HEAD
rg -i "<old-topic-keywords>"
```

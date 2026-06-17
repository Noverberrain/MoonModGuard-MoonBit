# Project Agent Guide

This is a MoonBit package for auditing MoonBit project manifests.

## Commands

- `moon info`
- `moon fmt`
- `moon test`
- `moon run cmd/main`

## Boundaries

- Keep the first release dependency-free.
- Treat `moon.mod` and `moon.pkg` inputs as strings or explicit snapshots.
- Do not add real filesystem scanning in v1; that is a later extension.
- Keep README and competition material focused on manifest and policy audit.

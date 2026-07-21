///|
fn mod_ok(input : String) -> @moonmodguard.ModuleManifest {
  match @moonmodguard.parse_mod(input) {
    Ok(manifest) => manifest
    Err(err) =>
      abort("unexpected mod parse error: " + @moonmodguard.format_error(err))
  }
}

///|
fn pkg_ok(input : String) -> @moonmodguard.PackageManifest {
  match @moonmodguard.parse_pkg(input) {
    Ok(manifest) => manifest
    Err(err) =>
      abort("unexpected pkg parse error: " + @moonmodguard.format_error(err))
  }
}

///|
fn dep_as_name(dep : @moonmodguard.Dependency) -> String {
  match dep.as_name {
    Some(name) => name
    None => abort("missing dependency alias for " + dep.source)
  }
}

///|
test "parse moon mod scalar and array fields" {
  let manifest = mod_ok(
    "name = \"wyc060514/tool\"\nversion = \"0.1.0\"\nreadme = \"README.md\"\nrepository = \"https://example.test/repo\"\nlicense = \"Apache-2.0\"\nkeywords = [ \"audit\", \"moonbit\" ]\ndescription = \"demo\"",
  )
  assert_eq(manifest.name, "wyc060514/tool")
  assert_eq(manifest.version, "0.1.0")
  assert_eq(manifest.license, "Apache-2.0")
  assert_eq(manifest.keywords.length(), 2)
  assert_eq(manifest.keywords[0], "audit")
  assert_eq(manifest.keywords[1], "moonbit")
}

///|
test "parse module imports with aliases" {
  let manifest = mod_ok(
    "name = \"wyc060514/tool\"\nlicense = \"Apache-2.0\"\nimport {\n  \"moonbitlang/x\" @x,\n  \"acme/dep\"\n}",
  )
  assert_eq(manifest.imports.length(), 2)
  assert_eq(manifest.imports[0].source, "moonbitlang/x")
  assert_eq(dep_as_name(manifest.imports[0]), "x")
  assert_eq(manifest.imports[1].source, "acme/dep")
}

///|
test "parse package imports with aliases" {
  let manifest = pkg_ok(
    "import {\n  \"wyc060514/core\" @core,\n  \"moonbitlang/x/json\" @json,\n}\noptions(\"is-main\": true)",
  )
  assert_eq(manifest.imports.length(), 2)
  assert_eq(manifest.imports[0].source, "wyc060514/core")
  assert_eq(dep_as_name(manifest.imports[0]), "core")
  assert_eq(dep_as_name(manifest.imports[1]), "json")
}

///|
test "policy reports missing metadata and license violations" {
  let project = @moonmodguard.project_from(
    mod_ok(
      "name = \"wyc060514/tool\"\nlicense = \"GPL-3.0\"\ndescription = \"a useful tool for MoonBit\"\nkeywords = [\"audit\", \"moonbit\"]",
    ),
    [],
  )
  let policy = @moonmodguard.default_policy()
  let report = @moonmodguard.evaluate_policy(project, policy)
  assert_eq(report.diagnostics.length(), 3)
  assert_eq(report.risk_count, 3)
  assert_eq(report.diagnostics[0].code, "missing-readme")
  assert_eq(report.diagnostics[1].code, "missing-repository")
  assert_eq(report.diagnostics[2].code, "license-not-allowed")
}

///|
test "policy reports duplicate and unknown dependencies" {
  let module_manifest = mod_ok(
    "name = \"wyc060514/tool\"\nreadme = \"README.md\"\nrepository = \"https://example.test/repo\"\nlicense = \"Apache-2.0\"\ndescription = \"a useful tool for MoonBit project auditing\"\nkeywords = [\"audit\"]\nimport {\n  \"unknown/dep\" @a,\n  \"unknown/dep\" @b\n}",
  )
  let project = @moonmodguard.project_from(module_manifest, [])
  let report = @moonmodguard.evaluate_policy(
    project,
    @moonmodguard.default_policy(),
  )
  assert_eq(report.diagnostics.length(), 2)
  assert_eq(report.diagnostics[0].code, "unknown-dependency")
  assert_eq(report.diagnostics[1].code, "duplicate-dependency")
}

///|
test "scan project combines module and package imports" {
  let module_manifest = mod_ok(
    "name = \"wyc060514/tool\"\nreadme = \"README.md\"\nrepository = \"https://example.test/repo\"\nlicense = \"Apache-2.0\"\ndescription = \"a useful tool for MoonBit project auditing\"\nkeywords = [\"audit\", \"moonbit\"]\nimport { \"moonbitlang/x\" @x }",
  )
  let package_manifest = pkg_ok("import { \"wyc060514/core\" @core }")
  let report = @moonmodguard.scan_project(@moonmodguard.ProjectSnapshot::{
    module_manifest,
    packages: [package_manifest],
  })
  assert_eq(report.project.name, "wyc060514/tool")
  assert_eq(report.dependency_count, 2)
  assert_eq(report.risk_count, 0)
}

///|
test "render markdown report" {
  let project = @moonmodguard.project_from(
    mod_ok(
      "name = \"wyc060514/tool\"\nlicense = \"GPL-3.0\"\ndescription = \"a useful tool for MoonBit\"\nkeywords = [\"audit\"]",
    ),
    [],
  )
  let report = @moonmodguard.evaluate_policy(
    project,
    @moonmodguard.default_policy(),
  )
  let markdown = @moonmodguard.render_markdown(report)
  assert_true(markdown.contains("# MoonModGuard Audit Report"))
  assert_true(markdown.contains("- Project: wyc060514/tool"))
  assert_true(markdown.contains("license-not-allowed"))
}

///|
test "validate_version accepts semver" {
  assert_true(@moonmodguard.validate_version("0.1.0"))
  assert_true(@moonmodguard.validate_version("1.2.3"))
  assert_true(@moonmodguard.validate_version("10.20.30"))
  assert_true(@moonmodguard.validate_version("0.1.0-alpha"))
  assert_false(@moonmodguard.validate_version(""))
  assert_false(@moonmodguard.validate_version("not-a-version"))
  assert_false(@moonmodguard.validate_version("1"))
}

///|
test "audit_snapshot convenience function" {
  match
    @moonmodguard.audit_snapshot(
      "name = \"wyc060514/tool\"\nlicense = \"MIT\"\ndescription = \"A test project for auditing\"\nkeywords = [ \"audit\" ]\nreadme = \"R.md\"\nrepository = \"https://example.test/repo\"\nversion = \"0.1.0\"\nimport { \"moonbitlang/x\" @x }",
      [],
    ) {
    Ok(report) => {
      assert_eq(report.risk_count, 0)
      assert_eq(report.dependency_count, 1)
    }
    Err(err) =>
      abort("unexpected parse error: " + @moonmodguard.format_error(err))
  }
}

///|
test "check_unused_dependency detects unused deps" {
  let manifest = mod_ok(
    "name = \"wyc060514/tool\"\nversion = \"0.1.0\"\nimport { \"unused-dep\" @unused }\nimport { \"used-dep\" @used }",
  )
  let pkg = pkg_ok("import { \"used-dep\" @used }")
  let diags = @moonmodguard.check_unused_dependency(manifest, [pkg])
  assert_eq(diags.length(), 1)
  assert_eq(diags[0].code, "unused-dependency")
}

///|
test "count_by_severity tallies correctly" {
  let d1 = @moonmodguard.Diagnostic::{
    code: "e1",
    message: "m1",
    severity: "error",
  }
  let d2 = @moonmodguard.Diagnostic::{
    code: "w1",
    message: "m2",
    severity: "warning",
  }
  let d3 = @moonmodguard.Diagnostic::{
    code: "e2",
    message: "m3",
    severity: "error",
  }
  let count = @moonmodguard.count_by_severity([d1, d2, d3], "error")
  assert_eq(count, 2)
}

///|
test "report_from builds audit directly" {
  let report = @moonmodguard.report_from(
    "test/proj",
    "MIT",
    "R.md",
    "https://r.test",
    "desc enough words here",
    ["tag"],
    [],
  )
  assert_eq(report.risk_count, 0)
}

///|
test "strict policy enforces longer description" {
  let project = @moonmodguard.ProjectModel::{
    name: "test/proj",
    license: "MIT",
    readme: "R.md",
    repository: "https://r.test",
    description: "short",
    keywords: ["audit", "test", "moonbit"],
    dependencies: [],
  }
  let report = @moonmodguard.evaluate_policy(
    project,
    @moonmodguard.strict_policy(),
  )
  assert_true(report.risk_count > 0)
}

///|
test "permissive policy allows everything" {
  let project = @moonmodguard.ProjectModel::{
    name: "test/proj",
    license: "Unlicense",
    readme: "",
    repository: "",
    description: "",
    keywords: [],
    dependencies: [
      @moonmodguard.Dependency::{
        source: "github.com/anyone/lib",
        version: None,
        as_name: None,
      },
    ],
  }
  let report = @moonmodguard.evaluate_policy(
    project,
    @moonmodguard.permissive_policy(),
  )
  assert_eq(report.risk_count, 0)
}

///|
test "validate_name requires owner/package format" {
  assert_true(@moonmodguard.validate_name("wyc060514/tool"))
  assert_true(@moonmodguard.validate_name("a/b"))
  assert_false(@moonmodguard.validate_name(""))
  assert_false(@moonmodguard.validate_name("notool"))
  assert_false(@moonmodguard.validate_name("a/b/c"))
}

///|
test "keyword_quality checks minimum meaningful keywords" {
  assert_true(
    @moonmodguard.keyword_quality(["audit", "moonbit", "supply-chain"], 2),
  )
  assert_false(@moonmodguard.keyword_quality(["a", "b", "c"], 2))
  assert_false(@moonmodguard.keyword_quality(["valid"], 2))
  assert_true(@moonmodguard.keyword_quality(["audit", "moonbit"], 2))
}

///|
test "is_risky_license detects copyleft licenses" {
  assert_true(@moonmodguard.is_risky_license("GPL-3.0"))
  assert_true(@moonmodguard.is_risky_license("AGPL-3.0"))
  assert_false(@moonmodguard.is_risky_license("MIT"))
  assert_false(@moonmodguard.is_risky_license("Apache-2.0"))
}

///|
test "TrustPolicy grades dependencies" {
  let policy = @moonmodguard.TrustPolicy::new()
    .trust("moonbitlang/")
    .allow("github.com/")
    .block("bad-domain/")
    .default_level(@moonmodguard.Blocked)
  let level1 = policy.check("moonbitlang/x")
  let level2 = policy.check("github.com/author/lib")
  let level3 = policy.check("bad-domain/dep")
  let level4 = policy.check("unknown/lib")
  assert_true(level1 is @moonmodguard.Trusted)
  assert_true(level2 is @moonmodguard.Allowed)
  assert_true(level3 is @moonmodguard.Blocked)
  assert_true(level4 is @moonmodguard.Blocked)
}

///|
test "evaluate_enhanced with CSP trust policy" {
  let project = @moonmodguard.ProjectModel::{
    name: "test/proj",
    license: "MIT",
    readme: "R.md",
    repository: "https://r.test",
    description: "A properly described test project",
    keywords: ["audit", "moonbit", "tool"],
    dependencies: [
      @moonmodguard.Dependency::{
        source: "moonbitlang/x",
        version: None,
        as_name: None,
      },
      @moonmodguard.Dependency::{
        source: "bad-domain/lib",
        version: None,
        as_name: None,
      },
    ],
  }
  let policy = @moonmodguard.EnhancedPolicy::default()
  let report = @moonmodguard.evaluate_enhanced(project, policy)
  assert_eq(report.risk_count, 1)
  assert_eq(report.diagnostics[0].code, "blocked-dependency")
}

///|
test "positioned_diagnostic renders GitHub annotation" {
  let d = @moonmodguard.positioned_diagnostic(
    "missing-readme", "README not found", "moon.mod", 12,
  )
  assert_eq(d.code, "missing-readme")
  assert_eq(d.file, "moon.mod")
  assert_eq(d.line, 12)
  let annotation = @moonmodguard.render_annotation(d)
  assert_true(annotation.contains("file=moon.mod"))
  assert_true(annotation.contains("line=12"))
}

///|
test "render_summary produces markdown table" {
  let d1 = @moonmodguard.Diagnostic::{
    code: "e1",
    message: "",
    severity: "error",
  }
  let d2 = @moonmodguard.Diagnostic::{
    code: "w1",
    message: "",
    severity: "warning",
  }
  let project = @moonmodguard.ProjectModel::{
    name: "test/proj",
    license: "MIT",
    readme: "R.md",
    repository: "r",
    description: "d",
    keywords: [],
    dependencies: [],
  }
  let report = @moonmodguard.AuditReport::{
    project,
    diagnostics: [d1, d2],
    risk_count: 2,
    dependency_count: 0,
  }
  let summary = @moonmodguard.render_summary(report)
  assert_true(summary.contains("| error    | 1 |"))
  assert_true(summary.contains("| warning  | 1 |"))
}

///|
test "render_full_report includes summary section" {
  let project = @moonmodguard.ProjectModel::{
    name: "test/proj",
    license: "MIT",
    readme: "R.md",
    repository: "r",
    description: "d",
    keywords: [],
    dependencies: [],
  }
  let report = @moonmodguard.AuditReport::{
    project,
    diagnostics: [],
    risk_count: 0,
    dependency_count: 0,
  }
  let full = @moonmodguard.render_full_report(report)
  assert_true(full.contains("## Project"))
  assert_true(full.contains("## Summary"))
  assert_true(full.contains("## Diagnostics"))
}

///|
test "batch_audit aggregates multiple projects" {
  let snapshot1 = @moonmodguard.ProjectSnapshot::{
    module_manifest: mod_ok(
      "name = \"a/proj1\"\nlicense = \"MIT\"\nreadme = \"R.md\"\nrepository = \"r\"\ndescription = \"A properly described test project\"\nkeywords = [\"audit\"]\nversion = \"0.1.0\"",
    ),
    packages: [],
  }
  let snapshot2 = @moonmodguard.ProjectSnapshot::{
    module_manifest: mod_ok("name = \"a/proj2\""),
    packages: [pkg_ok("import { \"unknown/dep\" }")],
  }
  let summary = @moonmodguard.batch_audit([snapshot1, snapshot2])
  assert_eq(summary.total_projects, 2)
  assert_eq(summary.projects_clean, 1)
  assert_eq(summary.projects_risky, 1)
}

///|
test "render_batch_summary outputs table" {
  let summary = @moonmodguard.AuditSummary::{
    total_projects: 5,
    total_diagnostics: 3,
    projects_clean: 2,
    projects_risky: 3,
  }
  let output = @moonmodguard.render_batch_summary(summary)
  assert_true(output.contains("| Projects audited | 5 |"))
  assert_true(output.contains("| Projects clean   | 2 |"))
  assert_true(output.contains("| Projects risky   | 3 |"))
}

// ---- Versioned dependency parsing ----

///|
test "parse versioned dependency with @version" {
  let manifest = mod_ok(
    "name = \"wyc060514/tool\"\nversion = \"0.1.0\"\nimport { \"moonbitlang/x@0.4.46\" @x }",
  )
  assert_eq(manifest.imports.length(), 1)
  assert_eq(manifest.imports[0].source, "moonbitlang/x")
  assert_eq(manifest.imports[0].version, Some("0.4.46"))
  assert_eq(dep_as_name(manifest.imports[0]), "x")
}

///|
test "parse unversioned dependency" {
  let manifest = mod_ok(
    "name = \"wyc060514/tool\"\nimport { \"moonbitlang/x\" @x }",
  )
  assert_eq(manifest.imports[0].version, None)
}

///|
test "parse @ in non-version position is kept as source" {
  let manifest = mod_ok(
    "name = \"wyc060514/tool\"\nimport { \"@scoped/pkg\" @pkg }",
  )
  assert_eq(manifest.imports[0].source, "@scoped/pkg")
  assert_eq(manifest.imports[0].version, None)
}

///|
test "check_version_consistency flags invalid versions" {
  let manifest = mod_ok(
    "name = \"wyc060514/tool\"\nimport { \"moonbitlang/x@0.x\" @x }",
  )
  let diags = @moonmodguard.check_version_consistency(manifest)
  assert_eq(diags.length(), 1)
  assert_eq(diags[0].code, "invalid-version")
}

///|
test "check_missing_versioned_dep detects package imports without module dep" {
  let manifest = mod_ok(
    "name = \"wyc060514/tool\"\nimport { \"moonbitlang/x@0.4.46\" @x }",
  )
  let pkg = pkg_ok(
    "import { \"moonbitlang/x\" @x }\nimport { \"unmatched/lib\" @lib }",
  )
  let diags = @moonmodguard.check_missing_versioned_dep(manifest, [pkg])
  assert_eq(diags.length(), 1)
  assert_eq(diags[0].code, "version-mismatch")
}

// ---- JSON escaping ----

///|
test "render_json escapes special characters" {
  let project = @moonmodguard.ProjectModel::{
    name: "test/proj",
    license: "MIT\nwith newline",
    readme: "R.md",
    repository: "r",
    description: "A \"cool\" tool",
    keywords: [],
    dependencies: [],
  }
  let report = @moonmodguard.AuditReport::{
    project,
    diagnostics: [
      @moonmodguard.Diagnostic::{
        code: "err",
        message: "has \"quotes\" and \\backslash",
        severity: "error",
      },
    ],
    risk_count: 1,
    dependency_count: 0,
  }
  let json = @moonmodguard.render_json(report)
  assert_true(json.has_prefix("{"))
  assert_true(json.contains("\\\\backslash"))
}

///|
test "render_json escape control characters" {
  let project = @moonmodguard.ProjectModel::{
    name: "t/p",
    license: "L",
    readme: "R",
    repository: "r",
    description: "d",
    keywords: [],
    dependencies: [],
  }
  let report = @moonmodguard.AuditReport::{
    project,
    diagnostics: [
      @moonmodguard.Diagnostic::{
        code: "x",
        message: "tab\there",
        severity: "info",
      },
    ],
    risk_count: 0,
    dependency_count: 0,
  }
  let json = @moonmodguard.render_json(report)
  assert_true(json.contains("\\t"))
}

// ---- Enhanced semver validation ----

///|
test "validate_version strict semver" {
  assert_true(@moonmodguard.validate_version("0.1.0"))
  assert_true(@moonmodguard.validate_version("1.2.3"))
  assert_true(@moonmodguard.validate_version("10.20.30"))
  assert_true(@moonmodguard.validate_version("0.1.0-alpha"))
  assert_true(@moonmodguard.validate_version("1.0.0-beta.1"))
  assert_true(@moonmodguard.validate_version("1.0.0+build.123"))
  assert_true(@moonmodguard.validate_version("1.0.0-alpha+exp.sha.5114f85"))
  assert_false(@moonmodguard.validate_version(""))
  assert_false(@moonmodguard.validate_version("not-a-version"))
  assert_false(@moonmodguard.validate_version("1"))
  assert_false(@moonmodguard.validate_version("1.0"))
  assert_false(@moonmodguard.validate_version("01.0.0"))
  assert_false(@moonmodguard.validate_version("1.02.3"))
  assert_false(@moonmodguard.validate_version("v1.0.0"))
  assert_false(@moonmodguard.validate_version("1.0.0-"))
  assert_false(@moonmodguard.validate_version("1.0.0+"))
}

// ---- SARIF rendering ----

///|
test "render_sarif produces valid structure" {
  let project = @moonmodguard.ProjectModel::{
    name: "test/proj",
    license: "MIT",
    readme: "R.md",
    repository: "r",
    description: "d",
    keywords: [],
    dependencies: [],
  }
  let report = @moonmodguard.AuditReport::{
    project,
    diagnostics: [
      @moonmodguard.Diagnostic::{
        code: "missing-readme",
        message: "README is not declared",
        severity: "error",
      },
    ],
    risk_count: 1,
    dependency_count: 0,
  }
  let sarif = @moonmodguard.render_sarif(report, "MoonModGuard")
  assert_true(sarif.has_prefix("{"))
  assert_true(sarif.contains("\"version\": \"2.1.0\""))
  assert_true(sarif.contains("missing-readme"))
  assert_true(sarif.contains("\"level\": \"error\""))
}

///|
test "render_sarif empty diagnostics" {
  let project = @moonmodguard.ProjectModel::{
    name: "test/proj",
    license: "Apache-2.0",
    readme: "R.md",
    repository: "r",
    description: "d",
    keywords: [],
    dependencies: [],
  }
  let report = @moonmodguard.AuditReport::{
    project,
    diagnostics: [],
    risk_count: 0,
    dependency_count: 0,
  }
  let sarif = @moonmodguard.render_sarif(report, "TestTool")
  assert_true(sarif.has_prefix("{"))
  assert_true(sarif.contains("\"results\": ["))
}

// ---- mooncake.yaml consistency ----

///|
test "parse_mooncake extracts fields" {
  let yaml = "name: moonmodguard\nversion: 0.2.0\ndescription: A test\nrepository: https://r.test\nlicense: Apache-2.0\nkeywords: [ \"audit\", \"moonbit\" ]"
  match @moonmodguard.parse_mooncake(yaml) {
    Ok(m) => {
      assert_eq(m.name, "moonmodguard")
      assert_eq(m.version, "0.2.0")
      assert_eq(m.license, "Apache-2.0")
      assert_eq(m.keywords.length(), 2)
    }
    Err(_) => abort("unexpected parse error")
  }
}

///|
test "check_mooncake_consistency detects mismatches" {
  let mod_manifest = mod_ok(
    "name = \"Noverberrain/tool\"\nversion = \"0.2.0\"\nlicense = \"MIT\"\nrepository = \"https://github.test/repo\"",
  )
  let mooncake = @moonmodguard.MooncakeManifest::{
    name: "Noverberrain/tool",
    version: "0.1.0",
    description: "",
    repository: "https://gitlink.test/repo",
    license: "Apache-2.0",
    keywords: [],
  }
  let diags = @moonmodguard.check_mooncake_consistency(mod_manifest, mooncake)
  assert_eq(diags.length(), 3)
  assert_eq(diags[0].code, "mooncake-version-mismatch")
  assert_eq(diags[1].code, "mooncake-license-mismatch")
  assert_eq(diags[2].code, "mooncake-repository-mismatch")
}

///|
test "check_mooncake_consistency all match" {
  let mod_manifest = mod_ok(
    "name = \"wyc/tool\"\nversion = \"1.0.0\"\nlicense = \"MIT\"\nrepository = \"https://r.test\"",
  )
  let mooncake = @moonmodguard.MooncakeManifest::{
    name: "wyc/tool",
    version: "1.0.0",
    description: "",
    repository: "https://r.test",
    license: "MIT",
    keywords: [],
  }
  let diags = @moonmodguard.check_mooncake_consistency(mod_manifest, mooncake)
  assert_eq(diags.length(), 0)
}

// ---- workspace scanning ----

///|
test "discover_packages finds current project" {
  let pkgs = @moonmodguard.discover_packages(".")
  assert_true(pkgs.length() > 0)
  let mut found = false
  for p in pkgs {
    if p.mod_text.contains("Noverberrain/moonmodguard") {
      found = true
      break
    }
  }
  assert_true(found)
}

///|
test "audit_workspace returns summary" {
  let summary = @moonmodguard.audit_workspace(".")
  assert_true(summary.total_projects > 0)
}

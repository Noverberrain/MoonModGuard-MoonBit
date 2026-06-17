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
    mod_ok("name = \"wyc060514/tool\"\nlicense = \"GPL-3.0\""),
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
    "name = \"wyc060514/tool\"\nreadme = \"README.md\"\nrepository = \"https://example.test/repo\"\nlicense = \"Apache-2.0\"\nimport {\n  \"unknown/dep\" @a,\n  \"unknown/dep\" @b\n}",
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
    "name = \"wyc060514/tool\"\nreadme = \"README.md\"\nrepository = \"https://example.test/repo\"\nlicense = \"Apache-2.0\"\nimport { \"moonbitlang/x\" @x }",
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
    mod_ok("name = \"wyc060514/tool\"\nlicense = \"GPL-3.0\""),
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

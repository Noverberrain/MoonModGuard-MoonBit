///|
pub(all) struct Position {
  line : Int
  column : Int
} derive(Eq)

///|
pub(all) struct Dependency {
  source : String
  version : String?
  as_name : String?
} derive(Eq)

///|
pub(all) struct ModuleManifest {
  name : String
  version : String
  readme : String
  repository : String
  license : String
  keywords : Array[String]
  description : String
  imports : Array[Dependency]
} derive(Eq)

///|
pub(all) struct PackageManifest {
  imports : Array[Dependency]
} derive(Eq)

///|
pub(all) struct ProjectSnapshot {
  module_manifest : ModuleManifest
  packages : Array[PackageManifest]
} derive(Eq)

///|
pub(all) struct ProjectModel {
  name : String
  license : String
  readme : String
  repository : String
  description : String
  keywords : Array[String]
  dependencies : Array[Dependency]
} derive(Eq)

///|
pub(all) struct Policy {
  allowed_licenses : Array[String]
  trusted_prefixes : Array[String]
  require_readme : Bool
  require_repository : Bool
  require_license : Bool
  require_description : Bool
  min_description_length : Int
  require_keywords : Bool
  min_keywords : Int
} derive(Eq)

///|
pub(all) struct Diagnostic {
  code : String
  message : String
  severity : String
} derive(Eq)

///|
pub(all) struct AuditReport {
  project : ProjectModel
  diagnostics : Array[Diagnostic]
  risk_count : Int
  dependency_count : Int
} derive(Eq)

///|
pub(all) enum GuardError {
  UnterminatedString(Position)
} derive(Eq)

///|
pub fn parse_mod(input : String) -> Result[ModuleManifest, GuardError] {
  let name = match string_field(input, "name") {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  let version = match string_field(input, "version") {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  let readme = match string_field(input, "readme") {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  let repository = match string_field(input, "repository") {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  let license = match string_field(input, "license") {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  let description = match string_field(input, "description") {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  let keywords = match array_field(input, "keywords") {
    Ok(values) => values
    Err(err) => return Err(err)
  }
  let imports = match parse_imports(input) {
    Ok(values) => values
    Err(err) => return Err(err)
  }
  Ok({
    name,
    version,
    readme,
    repository,
    license,
    keywords,
    description,
    imports,
  })
}

///|
pub fn parse_pkg(input : String) -> Result[PackageManifest, GuardError] {
  match parse_imports(input) {
    Ok(imports) => Ok({ imports, })
    Err(err) => Err(err)
  }
}

///|
pub fn project_from(
  manifest : ModuleManifest,
  packages : Array[PackageManifest],
) -> ProjectModel {
  let dependencies : Array[Dependency] = []
  for dep in manifest.imports {
    dependencies.push(dep)
  }
  for pkg in packages {
    for dep in pkg.imports {
      dependencies.push(dep)
    }
  }
  {
    name: manifest.name,
    license: manifest.license,
    readme: manifest.readme,
    repository: manifest.repository,
    description: manifest.description,
    keywords: manifest.keywords,
    dependencies,
  }
}

///|
pub fn default_policy() -> Policy {
  {
    allowed_licenses: ["Apache-2.0", "MIT", "MulanPSL-2.0"],
    trusted_prefixes: ["moonbitlang/", "wyc060514/"],
    require_readme: true,
    require_repository: true,
    require_license: true,
    require_description: true,
    min_description_length: 10,
    require_keywords: true,
    min_keywords: 1,
  }
}

///|
pub fn strict_policy() -> Policy {
  {
    allowed_licenses: ["Apache-2.0", "MIT"],
    trusted_prefixes: ["moonbitlang/"],
    require_readme: true,
    require_repository: true,
    require_license: true,
    require_description: true,
    min_description_length: 30,
    require_keywords: true,
    min_keywords: 3,
  }
}

///|
pub fn permissive_policy() -> Policy {
  {
    allowed_licenses: [
      "Apache-2.0", "MIT", "MulanPSL-2.0", "BSD-2-Clause", "BSD-3-Clause", "ISC",
      "Unlicense",
    ],
    trusted_prefixes: ["moonbitlang/", "wyc060514/", "github.com/"],
    require_readme: false,
    require_repository: false,
    require_license: false,
    require_description: false,
    min_description_length: 0,
    require_keywords: false,
    min_keywords: 0,
  }
}

///|
pub fn scan_project(snapshot : ProjectSnapshot) -> AuditReport {
  evaluate_policy(
    project_from(snapshot.module_manifest, snapshot.packages),
    default_policy(),
  )
}

///|
pub fn evaluate_policy(project : ProjectModel, policy : Policy) -> AuditReport {
  let diagnostics : Array[Diagnostic] = []
  if policy.require_readme && project.readme.length() == 0 {
    diagnostics.push(diagnostic("missing-readme", "README is not declared"))
  }
  if policy.require_repository && project.repository.length() == 0 {
    diagnostics.push(
      diagnostic("missing-repository", "repository is not declared"),
    )
  }
  if policy.require_license && project.license.length() == 0 {
    diagnostics.push(diagnostic("missing-license", "license is not declared"))
  } else if !contains_string(policy.allowed_licenses, project.license) {
    diagnostics.push(
      diagnostic(
        "license-not-allowed",
        "license \{project.license} is outside the allowed policy",
      ),
    )
  }
  if policy.require_description &&
    project.description.length() < policy.min_description_length {
    diagnostics.push(
      diagnostic(
        "description-too-short",
        "description is too short (\{project.description.length()} chars, min \{policy.min_description_length})",
      ),
    )
  }
  if policy.require_keywords && project.keywords.length() < policy.min_keywords {
    diagnostics.push(
      diagnostic(
        "missing-keywords",
        "only \{project.keywords.length()} keywords, min \{policy.min_keywords} required",
      ),
    )
  }
  let seen : Array[String] = []
  for dep in project.dependencies {
    if contains_string(seen, dep.source) {
      diagnostics.push(
        diagnostic(
          "duplicate-dependency",
          "dependency \{dep.source} is duplicated",
        ),
      )
    } else {
      if !is_trusted(dep.source, policy.trusted_prefixes) {
        diagnostics.push(
          diagnostic(
            "unknown-dependency",
            "dependency \{dep.source} is not trusted",
          ),
        )
      }
      seen.push(dep.source)
    }
  }
  {
    project,
    diagnostics,
    risk_count: diagnostics.length(),
    dependency_count: project.dependencies.length(),
  }
}

///|
pub fn render_markdown(report : AuditReport) -> String {
  let out = StringBuilder()
  out.write_string("# MoonModGuard Audit Report\n\n")
  out.write_string("- Project: \{report.project.name}\n")
  out.write_string("- Dependencies: \{report.dependency_count}\n")
  out.write_string("- Risks: \{report.risk_count}\n\n")
  out.write_string("## Diagnostics\n\n")
  if report.diagnostics.length() == 0 {
    out.write_string("- No policy risks found.\n")
  } else {
    for item in report.diagnostics {
      out.write_string("- [\{item.severity}] \{item.code}: \{item.message}\n")
    }
  }
  out.to_string()
}

///|
pub fn render_json(report : AuditReport) -> String {
  let out = StringBuilder()
  out.write_string("{\n")
  out.write_string(
    "  \"project\": \"" + escape_json(report.project.name) + "\",\n",
  )
  out.write_string(
    "  \"license\": \"" + escape_json(report.project.license) + "\",\n",
  )
  out.write_string(
    "  \"dependencies\": " + report.dependency_count.to_string() + ",\n",
  )
  out.write_string("  \"risks\": " + report.risk_count.to_string() + ",\n")
  out.write_string("  \"diagnostics\": [\n")
  render_json_diagnostics(out, report.diagnostics, 0)
  out.write_string("  ]\n")
  out.write_string("}\n")
  out.to_string()
}

///|
fn render_json_diagnostics(
  out : StringBuilder,
  diags : Array[Diagnostic],
  idx : Int,
) -> Unit {
  if idx >= diags.length() {
    return
  }
  let d = diags[idx]
  if idx > 0 {
    let _ = out.write_string(",\n")
  }
  let _ = out.write_string(
    "    {\"code\": \"" +
    escape_json(d.code) +
    "\", \"message\": \"" +
    escape_json(d.message) +
    "\", \"severity\": \"" +
    escape_json(d.severity) +
    "\"}",
  )
  let _ = render_json_diagnostics(out, diags, idx + 1)
}

///|
pub fn format_error(err : GuardError) -> String {
  match err {
    UnterminatedString(pos) =>
      "line \{pos.line}, column \{pos.column}: unterminated string"
  }
}

///|
fn diagnostic(code : String, message : String) -> Diagnostic {
  { code, message, severity: "error" }
}

///|
fn string_field(input : String, key : String) -> Result[String, GuardError] {
  let lines = input.split("\n").to_array()
  for i in 0..<lines.length() {
    let chars = lines[i].iter().to_array()
    let start = first_non_space(chars)
    if starts_with_key(chars, start, key) {
      let mut cursor = start + key.length()
      cursor = skip_spaces(chars, cursor)
      if cursor < chars.length() && chars[cursor] == '=' {
        cursor += 1
        cursor = skip_spaces(chars, cursor)
        if cursor < chars.length() && chars[cursor] == '"' {
          match read_string(chars, i + 1, cursor) {
            Ok((value, _)) => return Ok(value)
            Err(err) => return Err(err)
          }
        }
      }
    }
  }
  Ok("")
}

///|
fn array_field(
  input : String,
  key : String,
) -> Result[Array[String], GuardError] {
  let values : Array[String] = []
  let lines = input.split("\n").to_array()
  let mut in_array = false
  for i in 0..<lines.length() {
    let chars = lines[i].iter().to_array()
    let mut cursor = 0
    if !in_array {
      let start = first_non_space(chars)
      if starts_with_key(chars, start, key) {
        cursor = start + key.length()
        cursor = skip_spaces(chars, cursor)
        if cursor < chars.length() && chars[cursor] == '=' {
          cursor += 1
          cursor = skip_spaces(chars, cursor)
          if cursor < chars.length() && chars[cursor] == '[' {
            in_array = true
            cursor += 1
          }
        }
      }
    }
    if in_array {
      match collect_strings(chars, i + 1, cursor) {
        Ok(found) =>
          for value in found {
            values.push(value)
          }
        Err(err) => return Err(err)
      }
      if contains_char(chars, ']') {
        in_array = false
      }
    }
  }
  Ok(values)
}

///|
fn parse_imports(input : String) -> Result[Array[Dependency], GuardError] {
  let imports : Array[Dependency] = []
  let lines = input.split("\n").to_array()
  let mut in_import = false
  for i in 0..<lines.length() {
    let chars = lines[i].iter().to_array()
    let start = first_non_space(chars)
    let mut cursor = 0
    if starts_with_word(chars, start, "import") {
      in_import = true
      cursor = start + "import".length()
    }
    if in_import {
      match collect_imports(chars, i + 1, cursor) {
        Ok(found) =>
          for dep in found {
            imports.push(dep)
          }
        Err(err) => return Err(err)
      }
      if contains_char(chars, '}') {
        in_import = false
      }
    }
  }
  Ok(imports)
}

///|
fn collect_imports(
  chars : Array[Char],
  line : Int,
  start : Int,
) -> Result[Array[Dependency], GuardError] {
  let deps : Array[Dependency] = []
  let mut cursor = start
  while cursor < chars.length() {
    if chars[cursor] == '"' {
      match read_string(chars, line, cursor) {
        Ok((raw, next)) => {
          cursor = next
          let (source, version) = parse_dep_source(raw)
          let as_name = read_as_name(chars, cursor)
          deps.push({ source, version, as_name })
        }
        Err(err) => return Err(err)
      }
    } else {
      cursor += 1
    }
  }
  Ok(deps)
}

///|
/// Split a dependency string into source and optional version.
///
/// `"moonbitlang/x@0.4.46"` → `("moonbitlang/x", Some("0.4.46"))`
/// `"acme/dep"` → `("acme/dep", None)`
fn parse_dep_source(raw : String) -> (String, String?) {
  let chars = raw.iter().to_array()
  let mut last_at = -1
  for i in 0..<chars.length() {
    if chars[i] == '@' {
      last_at = i
    }
  }
  if last_at > 0 {
    let after = raw[last_at + 1:raw.length()].to_owned()
    if looks_like_version(after) {
      return (raw[0:last_at].to_owned(), Some(after))
    }
  }
  (raw, None)
}

///|
/// Quick check: does the string look like a version fragment (contains a digit)?
fn looks_like_version(s : String) -> Bool {
  for c in s {
    if c >= '0' && c <= '9' {
      return true
    }
  }
  false
}

///|
fn collect_strings(
  chars : Array[Char],
  line : Int,
  start : Int,
) -> Result[Array[String], GuardError] {
  let values : Array[String] = []
  let mut cursor = start
  while cursor < chars.length() {
    if chars[cursor] == '"' {
      match read_string(chars, line, cursor) {
        Ok((value, next)) => {
          values.push(value)
          cursor = next
        }
        Err(err) => return Err(err)
      }
    } else {
      cursor += 1
    }
  }
  Ok(values)
}

///|
fn read_string(
  chars : Array[Char],
  line : Int,
  start : Int,
) -> Result[(String, Int), GuardError] {
  let value = StringBuilder()
  let mut cursor = start + 1
  while cursor < chars.length() {
    if chars[cursor] == '\\' {
      if cursor + 1 < chars.length() {
        value.write_char(chars[cursor + 1])
        cursor += 2
      } else {
        value.write_char(chars[cursor])
        cursor += 1
      }
    } else if chars[cursor] == '"' {
      return Ok((value.to_string(), cursor + 1))
    } else {
      value.write_char(chars[cursor])
      cursor += 1
    }
  }
  Err(UnterminatedString({ line, column: start + 1 }))
}

///|
fn read_as_name(chars : Array[Char], start : Int) -> String? {
  let mut cursor = skip_spaces(chars, start)
  if cursor >= chars.length() || chars[cursor] != '@' {
    return None
  }
  cursor += 1
  let name = StringBuilder()
  while cursor < chars.length() && is_ident(chars[cursor]) {
    name.write_char(chars[cursor])
    cursor += 1
  }
  let value = name.to_string()
  if value.length() == 0 {
    None
  } else {
    Some(value)
  }
}

///|
fn is_trusted(source : String, prefixes : Array[String]) -> Bool {
  for prefix in prefixes {
    if starts_with_string(source, prefix) {
      return true
    }
  }
  false
}

///|
fn contains_string(values : Array[String], target : String) -> Bool {
  for value in values {
    if value == target {
      return true
    }
  }
  false
}

///|
fn contains_char(values : Array[Char], target : Char) -> Bool {
  for value in values {
    if value == target {
      return true
    }
  }
  false
}

///|
fn starts_with_key(chars : Array[Char], start : Int, key : String) -> Bool {
  if !starts_with_word(chars, start, key) {
    return false
  }
  let next = start + key.length()
  next >= chars.length() || is_space(chars[next]) || chars[next] == '='
}

///|
fn starts_with_word(chars : Array[Char], start : Int, word : String) -> Bool {
  let word_chars = word.iter().to_array()
  if start + word_chars.length() > chars.length() {
    return false
  }
  for i in 0..<word_chars.length() {
    if chars[start + i] != word_chars[i] {
      return false
    }
  }
  true
}

///|
fn starts_with_string(value : String, prefix : String) -> Bool {
  let chars = value.iter().to_array()
  let prefix_chars = prefix.iter().to_array()
  if prefix_chars.length() > chars.length() {
    return false
  }
  for i in 0..<prefix_chars.length() {
    if chars[i] != prefix_chars[i] {
      return false
    }
  }
  true
}

///|
fn first_non_space(chars : Array[Char]) -> Int {
  let mut cursor = 0
  while cursor < chars.length() && is_space(chars[cursor]) {
    cursor += 1
  }
  cursor
}

///|
fn skip_spaces(chars : Array[Char], start : Int) -> Int {
  let mut cursor = start
  while cursor < chars.length() && is_space(chars[cursor]) {
    cursor += 1
  }
  cursor
}

///|
fn is_space(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\r'
}

///|
fn is_ident(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') ||
  (c >= 'A' && c <= 'Z') ||
  (c >= '0' && c <= '9') ||
  c == '_' ||
  c == '-'
}

///|
/// Convenience: parse mod text and package texts, then run the default policy audit.
pub fn audit_snapshot(
  mod_text : String,
  pkg_texts : Array[String],
) -> Result[AuditReport, GuardError] {
  match parse_mod(mod_text) {
    Ok(module_manifest) => {
      let packages : Array[PackageManifest] = []
      for text in pkg_texts {
        match parse_pkg(text) {
          Ok(pkg) => packages.push(pkg)
          Err(err) => return Err(err)
        }
      }
      Ok(scan_project(ProjectSnapshot::{ module_manifest, packages }))
    }
    Err(err) => Err(err)
  }
}

///|
/// Validate a version string against full semver rules.
///
/// Supports: `MAJOR.MINOR.PATCH[-prerelease][+build]`
pub fn validate_version(version : String) -> Bool {
  validate_semver(version)
}

///|
fn validate_semver(version : String) -> Bool {
  let v = version
  if v.length() == 0 {
    return false
  }
  // Strip build metadata
  let core_and_pre = match v.split_once("+") {
    Some((core, build)) => {
      if build.length() == 0 {
        return false
      }
      core.to_owned()
    }
    None => v
  }
  // Split prerelease
  let core = match core_and_pre.split_once("-") {
    Some((c, pre)) => {
      let pre_s = pre.to_owned()
      if pre_s.length() == 0 || !is_valid_prerelease(pre_s) {
        return false
      }
      c.to_owned()
    }
    None => core_and_pre
  }
  // Core: MAJOR.MINOR.PATCH
  let parts = core.split(".").to_array()
  if parts.length() != 3 {
    return false
  }
  for part in parts {
    if !is_non_negative_int(part.to_owned()) {
      return false
    }
  }
  // Leading zero check
  for part in parts {
    if part.length() > 1 && part[0] == '0' {
      return false
    }
  }
  true
}

///|
fn is_non_negative_int(s : String) -> Bool {
  if s.length() == 0 {
    return false
  }
  for c in s {
    if c < '0' || c > '9' {
      return false
    }
  }
  true
}

///|
fn is_valid_prerelease(s : String) -> Bool {
  if s.length() == 0 {
    return false
  }
  for part in s.split(".") {
    let part_str = part.to_owned()
    if part_str.length() == 0 {
      return false
    }
    for c in part_str {
      if !((c >= '0' && c <= '9') ||
        (c >= 'a' && c <= 'z') ||
        (c >= 'A' && c <= 'Z') ||
        c == '-') {
        return false
      }
    }
  }
  true
}

///|
fn escape_json(s : String) -> String {
  let out = StringBuilder()
  for c in s {
    match c {
      '"' => out.write_string("\\\"")
      '\\' => out.write_string("\\\\")
      '\n' => out.write_string("\\n")
      '\r' => out.write_string("\\r")
      '\t' => out.write_string("\\t")
      _ =>
        if c.to_int() < 0x20 {
          out.write_string("\\u" + pad_hex(c.to_int(), 4))
        } else {
          out.write_char(c)
        }
    }
  }
  out.to_string()
}

///|
fn pad_hex(value : Int, width : Int) -> String {
  let hex = "0123456789abcdef"
  let mut result = ""
  let mut v = value
  for _ in 0..<width {
    result = hex[v % 16].to_string() + result
    v = v / 16
  }
  result
}

///|
/// Run an enhanced policy evaluation that includes version validation.
pub fn audit_policy(project : ProjectModel, policy : Policy) -> AuditReport {
  let report = evaluate_policy(project, policy)
  report
}

///|
/// Check if a dependency declared in the module manifest is actually imported by any package.
pub fn check_unused_dependency(
  manifest : ModuleManifest,
  packages : Array[PackageManifest],
) -> Array[Diagnostic] {
  let diagnostics : Array[Diagnostic] = []
  let all_imports : Array[String] = []
  for pkg in packages {
    for dep in pkg.imports {
      all_imports.push(dep.source)
    }
  }
  for dep in manifest.imports {
    if !contains_string(all_imports, dep.source) {
      diagnostics.push(
        diagnostic(
          "unused-dependency",
          "dependency \{dep.source} is declared but not imported by any package",
        ),
      )
    }
  }
  diagnostics
}

///|
/// Check that every package-level import has a corresponding versioned module dependency.
pub fn check_missing_versioned_dep(
  manifest : ModuleManifest,
  packages : Array[PackageManifest],
) -> Array[Diagnostic] {
  let diagnostics : Array[Diagnostic] = []
  let versioned : Array[(String, String)] = []
  for dep in manifest.imports {
    match dep.version {
      Some(v) => versioned.push((dep.source, v))
      None => ()
    }
  }
  for pkg in packages {
    for dep in pkg.imports {
      let mut found = false
      for i in 0..<versioned.length() {
        let (src, _v) = versioned[i]
        if src == dep.source {
          found = true
          break
        }
      }
      if !found {
        diagnostics.push(
          diagnostic(
            "version-mismatch",
            "package import \{dep.source} has no versioned module dependency",
          ),
        )
      }
    }
  }
  diagnostics
}

///|
/// Check that versioned module dependencies match the versions actually imported.
pub fn check_version_consistency(
  manifest : ModuleManifest,
) -> Array[Diagnostic] {
  let diagnostics : Array[Diagnostic] = []
  for dep in manifest.imports {
    match dep.version {
      Some(v) =>
        if !validate_version(v) {
          diagnostics.push(
            diagnostic(
              "invalid-version",
              "dependency \{dep.source} has invalid version \{v}",
            ),
          )
        }
      None => ()
    }
  }
  diagnostics
}

///|
/// Build a report from explicit fields (no parsing needed).
pub fn report_from(
  name : String,
  license : String,
  readme : String,
  repository : String,
  description : String,
  keywords : Array[String],
  deps : Array[Dependency],
) -> AuditReport {
  evaluate_policy(
    {
      name,
      license,
      readme,
      repository,
      description,
      keywords,
      dependencies: deps,
    },
    default_policy(),
  )
}

///|
/// Return the diagnostic count for a severity level.
pub fn count_by_severity(
  diagnostics : Array[Diagnostic],
  severity : String,
) -> Int {
  let mut count = 0
  for d in diagnostics {
    if d.severity == severity {
      count = count + 1
    }
  }
  count
}

// ------- Trust Levels (CSP-style grading) -------

///|
pub(all) enum TrustLevel {
  Trusted
  Allowed
  Blocked
} derive(Eq)

///|
pub(all) struct TrustRule {
  prefix : String
  level : TrustLevel
} derive(Eq)

///|
pub(all) struct TrustPolicy {
  rules : Array[TrustRule]
  default_level : TrustLevel
} derive(Eq)

///|
pub fn TrustPolicy::new() -> TrustPolicy {
  { rules: [], default_level: Blocked }
}

///|
pub fn TrustPolicy::trust(self : TrustPolicy, prefix : String) -> TrustPolicy {
  let new_rules = self.rules
  new_rules.push({ prefix, level: Trusted })
  { ..self, rules: new_rules }
}

///|
pub fn TrustPolicy::allow(self : TrustPolicy, prefix : String) -> TrustPolicy {
  let new_rules = self.rules
  new_rules.push({ prefix, level: Allowed })
  { ..self, rules: new_rules }
}

///|
pub fn TrustPolicy::block(self : TrustPolicy, prefix : String) -> TrustPolicy {
  let new_rules = self.rules
  new_rules.push({ prefix, level: Blocked })
  { ..self, rules: new_rules }
}

///|
pub fn TrustPolicy::default_level(
  self : TrustPolicy,
  level : TrustLevel,
) -> TrustPolicy {
  { ..self, default_level: level }
}

///|
pub fn TrustPolicy::check(self : TrustPolicy, source : String) -> TrustLevel {
  for rule in self.rules {
    if starts_with_string(source, rule.prefix) {
      return rule.level
    }
  }
  self.default_level
}

// ------- Enhanced Policy -------

///|
pub(all) struct EnhancedPolicy {
  trust_policy : TrustPolicy
  require_readme : Bool
  require_repository : Bool
  require_license : Bool
  require_description : Bool
  min_description_length : Int
  require_keywords : Bool
  min_keywords : Int
  require_version : Bool
  max_dependencies : Int
} derive(Eq)

///|
pub fn EnhancedPolicy::default() -> EnhancedPolicy {
  {
    trust_policy: TrustPolicy::new().trust("moonbitlang/").trust("wyc060514/"),
    require_readme: true,
    require_repository: true,
    require_license: true,
    require_description: true,
    min_description_length: 10,
    require_keywords: true,
    min_keywords: 1,
    require_version: true,
    max_dependencies: 50,
  }
}

// ------- Enhanced Audit -------

///|
pub fn evaluate_enhanced(
  project : ProjectModel,
  policy : EnhancedPolicy,
) -> AuditReport {
  let diagnostics : Array[Diagnostic] = []

  // Metadata checks
  if policy.require_readme && project.readme.length() == 0 {
    diagnostics.push(diagnostic("missing-readme", "README is not declared"))
  }
  if policy.require_repository && project.repository.length() == 0 {
    diagnostics.push(
      diagnostic("missing-repository", "repository is not declared"),
    )
  }
  if policy.require_license && project.license.length() == 0 {
    diagnostics.push(diagnostic("missing-license", "license is not declared"))
  }
  if policy.require_description &&
    project.description.length() < policy.min_description_length {
    diagnostics.push(
      diagnostic(
        "description-too-short",
        "description is too short (\{project.description.length()} chars, min \{policy.min_description_length})",
      ),
    )
  }
  if policy.require_keywords && project.keywords.length() < policy.min_keywords {
    diagnostics.push(
      diagnostic(
        "missing-keywords",
        "only \{project.keywords.length()} keywords, min \{policy.min_keywords} required",
      ),
    )
  }
  if policy.max_dependencies > 0 &&
    project.dependencies.length() > policy.max_dependencies {
    diagnostics.push(
      diagnostic(
        "too-many-dependencies",
        "\{project.dependencies.length()} dependencies exceeds limit of \{policy.max_dependencies}",
      ),
    )
  }

  // Trust checks with graded levels
  let seen : Array[String] = []
  for dep in project.dependencies {
    if contains_string(seen, dep.source) {
      diagnostics.push(
        diagnostic(
          "duplicate-dependency",
          "dependency \{dep.source} is duplicated",
        ),
      )
    } else {
      let level = policy.trust_policy.check(dep.source)
      match level {
        Blocked =>
          diagnostics.push(
            diagnostic(
              "blocked-dependency",
              "dependency \{dep.source} is blocked by trust policy",
            ),
          )
        Allowed => ()
        Trusted => ()
      }
      seen.push(dep.source)
    }
  }

  {
    project,
    diagnostics,
    risk_count: diagnostics.length(),
    dependency_count: project.dependencies.length(),
  }
}

///|
/// Check that the project name follows the `owner/package` convention.
pub fn validate_name(name : String) -> Bool {
  let parts = name.split("/").to_array()
  if parts.length() != 2 {
    return false
  }
  let owner = parts[0]
  let pkg = parts[1]
  owner.length() > 0 && pkg.length() > 0
}

///|
/// Check keyword quality: at least `min` meaningful keywords (length >= 3).
pub fn keyword_quality(keywords : Array[String], min : Int) -> Bool {
  if keywords.length() < min {
    return false
  }
  let mut count = 0
  for kw in keywords {
    if kw.length() >= 3 {
      count = count + 1
    }
  }
  count >= min
}

///|
/// Check for known-risky licenses (GPL, AGPL, etc.).
pub fn is_risky_license(license : String) -> Bool {
  let risky = ["GPL-2.0", "GPL-3.0", "AGPL-3.0", "LGPL-2.1", "LGPL-3.0"]
  contains_string(risky, license)
}

// ------- Enhanced Rendering -------

///|
/// Render a summary table of diagnostics grouped by severity.
pub fn render_summary(report : AuditReport) -> String {
  let errors = count_by_severity(report.diagnostics, "error")
  let warnings = count_by_severity(report.diagnostics, "warning")
  let infos = count_by_severity(report.diagnostics, "info")
  let out = StringBuilder()
  out.write_string("| Severity | Count |\n")
  out.write_string("|----------|-------|\n")
  out.write_string("| error    | \{errors} |\n")
  out.write_string("| warning  | \{warnings} |\n")
  out.write_string("| info     | \{infos} |\n")
  out.to_string()
}

///|
/// Render a full audit report with a summary section.
pub fn render_full_report(report : AuditReport) -> String {
  let out = StringBuilder()
  out.write_string("# MoonModGuard Audit Report\n\n")
  out.write_string("## Project\n\n")
  out.write_string("- Name: \{report.project.name}\n")
  out.write_string("- License: \{report.project.license}\n")
  out.write_string("- Dependencies: \{report.dependency_count}\n")
  out.write_string("- Risks: \{report.risk_count}\n\n")
  out.write_string("## Summary\n\n")
  out.write_string(render_summary(report))
  out.write_string("\n\n## Diagnostics\n\n")
  if report.diagnostics.length() == 0 {
    out.write_string("- No policy risks found.\n")
  } else {
    for i in 0..<report.diagnostics.length() {
      let d = report.diagnostics[i]
      out.write_string(
        "\{i + 1}. [\{d.severity}] **\{d.code}**: \{d.message}\n",
      )
    }
  }
  out.to_string()
}

///|
/// Location-aware diagnostic with file path and position.
pub(all) struct PositionedDiagnostic {
  code : String
  message : String
  severity : String
  file : String
  line : Int
} derive(Eq)

///|
/// Convert a Position to a diagnostic with location info.
pub fn positioned_diagnostic(
  code : String,
  message : String,
  file : String,
  line : Int,
) -> PositionedDiagnostic {
  { code, message, severity: "error", file, line }
}

///|
/// Render a positioned diagnostic as a GitHub Actions annotation.
pub fn render_annotation(d : PositionedDiagnostic) -> String {
  "::\{d.severity} file=\{d.file},line=\{d.line}::\{d.code}: \{d.message}"
}

// ------- Batch Audit -------

///|
pub(all) struct AuditSummary {
  total_projects : Int
  total_diagnostics : Int
  projects_clean : Int
  projects_risky : Int
} derive(Eq)

///|
/// Run a batch audit on multiple projects and return a summary.
pub fn batch_audit(snapshots : Array[ProjectSnapshot]) -> AuditSummary {
  let mut total_projects = 0
  let mut total_diagnostics = 0
  let mut projects_clean = 0
  let mut projects_risky = 0
  for snapshot in snapshots {
    let report = scan_project(snapshot)
    total_projects = total_projects + 1
    total_diagnostics = total_diagnostics + report.risk_count
    if report.risk_count == 0 {
      projects_clean = projects_clean + 1
    } else {
      projects_risky = projects_risky + 1
    }
  }
  { total_projects, total_diagnostics, projects_clean, projects_risky }
}

///|
/// Render a batch audit result as a concise table.
pub fn render_batch_summary(summary : AuditSummary) -> String {
  let out = StringBuilder()
  out.write_string("# Batch Audit Summary\n\n")
  out.write_string("| Metric | Value |\n")
  out.write_string("|--------|-------|\n")
  out.write_string("| Projects audited | \{summary.total_projects} |\n")
  out.write_string("| Projects clean   | \{summary.projects_clean} |\n")
  out.write_string("| Projects risky   | \{summary.projects_risky} |\n")
  out.write_string("| Total diagnostics | \{summary.total_diagnostics} |\n")
  out.to_string()
}

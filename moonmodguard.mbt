///|
pub(all) struct Position {
  line : Int
  column : Int
} derive(Eq)

///|
pub(all) struct Dependency {
  source : String
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
  out.write_string("  \"project\": \"" + report.project.name + "\",\n")
  out.write_string("  \"license\": \"" + report.project.license + "\",\n")
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
    d.code +
    "\", \"message\": \"" +
    d.message +
    "\", \"severity\": \"" +
    d.severity +
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
        Ok((source, next)) => {
          cursor = next
          let as_name = read_as_name(chars, cursor)
          deps.push({ source, as_name })
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

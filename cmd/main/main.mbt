///|
fn main {
  let mod_text = "name = \"wyc060514/moonmodguard\"\n" +
    "version = \"0.1.0\"\n" +
    "readme = \"README.md\"\n" +
    "repository = \"https://gitlink.org.cn/Wyc060514/moonmodguard\"\n" +
    "license = \"Apache-2.0\"\n" +
    "description = \"A MoonBit project manifest and supply-chain policy auditor.\"\n" +
    "keywords = [ \"audit\", \"moonbit\" ]\n" +
    "import { \"moonbitlang/x\" @x }\n" +
    "import { \"wyc060514/lib\" @lib }"
  let pkg_text = ""
  match (@guard.parse_mod(mod_text), @guard.parse_pkg(pkg_text)) {
    (Ok(module_manifest), Ok(package_manifest)) => {
      let report = @guard.scan_project(@guard.ProjectSnapshot::{
        module_manifest,
        packages: [package_manifest],
      })
      println("MoonModGuard demo")
      println("project=" + report.project.name)
      println("dependencies=\{report.dependency_count}")
      println("risks=\{report.risk_count}")
      println("--- markdown ---")
      println(@guard.render_markdown(report))
    }
    (Err(err), _) => println("module parse error: " + @guard.format_error(err))
    (_, Err(err)) => println("package parse error: " + @guard.format_error(err))
  }
}

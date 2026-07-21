///|
fn main raise {
  let args = @sys.get_cli_args()
  let mut input : String? = None
  let mut json_mode = false
  let mut enhanced = false
  let mut sarif = false
  let mut workspace = false
  let mut annotations = false

  let mut i = 1
  while i < args.length() {
    let arg = args[i]
    if arg == "-h" || arg == "--help" {
      print_usage()
      return
    } else if arg == "--json" {
      json_mode = true
      i = i + 1
    } else if arg == "--enhanced" {
      enhanced = true
      i = i + 1
    } else if arg == "--sarif" {
      sarif = true
      i = i + 1
    } else if arg == "--annotations" {
      annotations = true
      i = i + 1
    } else if arg == "--workspace" || arg == "-w" {
      workspace = true
      i = i + 1
    } else if !arg.has_prefix("-") {
      input = Some(arg)
      i = i + 1
    } else {
      println("moonmodguard: unknown option: " + arg)
      print_usage()
      abort("")
    }
  }

  if workspace {
    let root = match input {
      Some(dir) => dir
      None => "."
    }
    let summary = @guard.audit_workspace(root)
    println(@guard.render_batch_summary(summary))
    return
  }

  let path = match input {
    Some(p) => p
    None => {
      println(
        "moonmodguard: provide a moon.mod file path or --workspace for batch audit",
      )
      print_usage()
      abort("")
    }
  }

  let manifest = match @guard.parse_mod(@fs.read_file_to_string(path)) {
    Ok(m) => m
    Err(err) => {
      println("moonmodguard: parse error: " + @guard.format_error(err))
      abort("")
    }
  }
  let pkg_text = ""
  let report = match @guard.parse_pkg(pkg_text) {
    Ok(pkg) =>
      if enhanced {
        let project = @guard.project_from(manifest, [pkg])
        @guard.evaluate_enhanced(project, @guard.EnhancedPolicy::default())
      } else {
        @guard.scan_project(@guard.ProjectSnapshot::{
          module_manifest: manifest,
          packages: [pkg],
        })
      }
    Err(_) =>
      @guard.scan_project(@guard.ProjectSnapshot::{
        module_manifest: manifest,
        packages: [],
      })
  }

  if annotations {
    for d in report.diagnostics {
      let pd = @guard.positioned_diagnostic(d.code, d.message, path, 1)
      println(@guard.render_annotation(pd))
    }
  } else if sarif {
    println(@guard.render_sarif(report, "MoonModGuard"))
  } else if json_mode {
    println(@guard.render_json(report))
  } else {
    println(@guard.render_full_report(report))
  }
}

///|
fn print_usage() -> Unit {
  println("Usage: moonmodguard [options] [<moon.mod>]")
  println("       moonmodguard --workspace [<directory>]")
  println("")
  println("Options:")
  println("  --json        Output as JSON (default: Markdown)")
  println("  --sarif       Output as SARIF v2.1.0")
  println("  --annotations Output as GitHub Actions workflow commands")
  println("  --enhanced    Use EnhancedPolicy with trust grading")
  println("  --workspace   Recursively audit all packages under a directory")
  println("  -w            Short for --workspace")
  println("  -h, --help    Show this help")
}

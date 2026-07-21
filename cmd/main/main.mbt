///|
fn main raise {
  let args = @sys.get_cli_args()
  let mut input : String? = None
  let mut json_mode = false
  let mut enhanced = false

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
    } else if i == args.length() - 1 && !arg.has_prefix("-") {
      input = Some(arg)
      i = i + 1
    } else {
      println("moonmodguard: unknown option: " + arg)
      print_usage()
      abort("")
    }
  }

  let mod_text = match input {
    Some(path) => @fs.read_file_to_string(path)
    None => {
      println(
        "moonmodguard: reading from stdin is not supported on this target; provide a file path",
      )
      print_usage()
      abort("")
    }
  }

  let manifest = match @guard.parse_mod(mod_text) {
    Ok(m) => m
    Err(err) => {
      println("moonmodguard: parse error: " + @guard.format_error(err))
      abort("")
    }
  }
  let pkg_text = "" // single pkg not read from separate file for now

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

  if json_mode {
    println(@guard.render_json(report))
  } else {
    println(@guard.render_full_report(report))
  }
}

///|
fn print_usage() -> Unit {
  println("Usage: moonmodguard [options] [<moon.mod>]")
  println("")
  println("Options:")
  println("  --json        Output as JSON (default: Markdown)")
  println("  --enhanced    Use EnhancedPolicy with trust grading")
  println("  -h, --help    Show this help")
}

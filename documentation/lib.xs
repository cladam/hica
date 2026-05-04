-- xs-cli-args: declarative argv parser.
--
--   import cli_args
--   let spec = cli_args.spec("greet")
--       .arg("name", #{help: "who to greet", required: true})
--       .opt("upper", #{help: "shout the greeting", flag: true})
--       .opt("count", #{help: "how many times", default: "1"})
--   let parsed = spec.parse(args)
--   println(parsed.get("name"), parsed.flag("upper"))
--
-- Subcommands:
--   spec.cmd("hello", subspec).cmd("bye", other)
--   parsed.subcommand          // "hello" | "bye" | null
--   parsed.sub                 // ParsedArgs for the chosen subcommand

fn _empty_spec(name) {
    return #{
        name: name,
        positional: [],
        options: #{},
        commands: #{},
        about: "",
    }
}

fn spec(name) {
    let s = _empty_spec(name)
    return #{
        _spec: s,
        about: |text| { s.about = text; return _wrap(s) },
        arg:   |n, opts| { s.positional.push(_norm_arg(n, opts)); return _wrap(s) },
        opt:   |n, opts| { s.options.set(n, _norm_opt(n, opts)); return _wrap(s) },
        cmd:   |n, sub|  { s.commands.set(n, sub._spec); return _wrap(s) },
        parse: |argv|    { return _parse(s, argv) },
        help:  ||         { return _format_help(s) },
    }
}

fn _wrap(s) { return spec(s.name).._unsafe_inherit(s) }
-- the chained DSL above mutates `s` in place; reusing the wrapper is fine

fn _norm_arg(name, opts) {
    let o = opts ?? #{}
    return #{
        name: name,
        help: o.get("help") ?? "",
        required: o.get("required") ?? false,
        default: o.get("default") ?? null,
    }
}

fn _norm_opt(name, opts) {
    let o = opts ?? #{}
    return #{
        name: name,
        help: o.get("help") ?? "",
        flag: o.get("flag") ?? false,
        default: o.get("default") ?? null,
        short: o.get("short") ?? null,
    }
}

fn _parse(s, argv) {
    var values = #{}
    var flags = #{}
    var positional = []
    var subcommand = null
    var sub_args = []

    var i = 0
    while i < argv.len() {
        let a = argv[i]
        if a.startswith("--") {
            let body = a.slice(2, a.len())
            let eq = body.find("=")
            let key = if eq >= 0 { body.slice(0, eq) } else { body }
            let inline_v = if eq >= 0 { body.slice(eq + 1, body.len()) } else { null }
            let opt = s.options.get(key)
            if opt == null {
                throw "unknown option: --{key}"
            }
            if opt.flag {
                flags.set(key, true)
            } else {
                let v = if inline_v != null {
                    inline_v
                } else {
                    i = i + 1
                    if i >= argv.len() { throw "option --{key} needs a value" }
                    argv[i]
                }
                values.set(key, v)
            }
        } else if a.startswith("-") and a.len() == 2 {
            let short = a.slice(1, 2)
            var found = null
            for k in s.options.keys() {
                if s.options.get(k).short == short { found = k; break }
            }
            if found == null { throw "unknown short option: -{short}" }
            let opt = s.options.get(found)
            if opt.flag {
                flags.set(found, true)
            } else {
                i = i + 1
                if i >= argv.len() { throw "option -{short} needs a value" }
                values.set(found, argv[i])
            }
        } else if subcommand == null and s.commands.contains(a) {
            subcommand = a
            sub_args = argv.slice(i + 1, argv.len())
            i = argv.len()
        } else {
            positional.push(a)
        }
        i = i + 1
    }

    -- defaults + required
    var args_map = #{}
    for j in 0..s.positional.len() {
        let p = s.positional[j]
        if j < positional.len() {
            args_map.set(p.name, positional[j])
        } else if p.default != null {
            args_map.set(p.name, p.default)
        } else if p.required {
            throw "missing required positional <{p.name}>"
        }
    }
    for k in s.options.keys() {
        let o = s.options.get(k)
        if not values.contains(k) and o.default != null and not o.flag {
            values.set(k, o.default)
        }
    }

    var sub = null
    if subcommand != null {
        sub = _parse(s.commands.get(subcommand), sub_args)
    }

    return #{
        get: |n| args_map.get(n) ?? values.get(n),
        flag: |n| flags.get(n) ?? false,
        positional: positional,
        subcommand: subcommand,
        sub: sub,
    }
}

fn _format_help(s) {
    var out = "usage: " + s.name
    for p in s.positional {
        out = out + " <" + p.name + ">"
    }
    if not s.options.is_empty() { out = out + " [OPTIONS]" }
    if not s.commands.is_empty() { out = out + " <COMMAND>" }
    out = out + "\n"
    if s.about.len() > 0 { out = out + s.about + "\n\n" }
    if not s.positional.is_empty() {
        out = out + "Arguments:\n"
        for p in s.positional {
            out = out + "  <" + p.name + ">  " + (p.help ?? "") + "\n"
        }
    }
    if not s.options.is_empty() {
        out = out + "\nOptions:\n"
        for k in s.options.keys() {
            let o = s.options.get(k)
            out = out + "  --" + k
            if not o.flag { out = out + " <value>" }
            out = out + "  " + (o.help ?? "") + "\n"
        }
    }
    return out
}

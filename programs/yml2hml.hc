// yml2hml.hc — Convert YAML files to HML format
//
// Usage:
//   hica run examples/yml2hml.hc -- input.yml
//   hica run examples/yml2hml.hc -- input.yml output.hml
//
// Handles: scalars, nested objects, arrays of scalars (- item),
//          booleans, nulls, integers, floats, quoted strings.
// Limitations: does not handle multi-line strings, anchors/aliases,
//              flow mappings, or complex keys.

// --- YAML line classification ---

type YamlLine {
    YKeyVal(indent: int, key: string, value: string),
    YListItem(indent: int, value: string),
    YKeyOnly(indent: int, key: string),
    YBlank,
    YComment(text: string)
}

// Count leading spaces
fun count_indent(s: string) : int {
    let chars = split(s, "")
    count_spaces(chars, 0)
}

fun count_spaces(chars: list<string>, acc: int) : int =>
    match chars {
        [" ", ..rest] => count_spaces(rest, acc + 1),
        _ => acc
    }

// Strip leading/trailing whitespace
fun strip(s: string) : string => trim(s)

// Check if a string starts with a given prefix
fun has_prefix(s: string, pfx: string) : bool => starts_with(s, pfx)

// Remove surrounding quotes if present
fun unquote(s: string) : string {
    let t = strip(s)
    let len = str_length(t)
    if len >= 2 && (has_prefix(t, "'") || has_prefix(t, "\"")) {
        t[1:len - 1]
    } else {
        t
    }
}

// Classify a YAML value for HML output
fun is_yaml_bool(v: string) : bool => match v {
    "true" | "false" | "yes" | "no" | "on" | "off" => true,
    _ => false
}

fun yaml_bool_to_hml(v: string) : string => match v {
    "true" | "yes" | "on" => "true",
    _ => "false"
}

fun is_yaml_null(v: string) : bool => v == "null" || v == "~"

fun hml_value(s: string) : string {
    let v = strip(s)
    if v == "" { "\"\"" }
    else if v == "[]" { "[]" }
    else if is_yaml_bool(v) { yaml_bool_to_hml(v) }
    else if is_yaml_null(v) { "null" }
    else {
        match parse_int(v) {
            Some(_) => v,
            None => match parse_float(v) {
                Some(_) => v,
                None => {
                    if has_prefix(v, "'") { "\"" + unquote(v) + "\"" }
                    else if has_prefix(v, "\"") { v }
                    else { "\"" + v + "\"" }
                }
            }
        }
    }
}

// Convert underscores to dashes in key names (YAML convention -> HML convention)
fun to_hml_key(k: string) : string => replace(k, "_", "-")

// Parse a single YAML line into a YamlLine
fun parse_yaml_line(line: string) : YamlLine {
    let trimmed = strip(line)
    if trimmed == "" { YBlank }
    else {
        if has_prefix(trimmed, "#") { YComment(trimmed[1:]) }
        else {
            let indent = count_indent(line)
            if has_prefix(trimmed, "- ") {
                YListItem(indent, strip(trimmed[2:]))
            } else {
                // Look for key: value
                match index_of(trimmed, ":") {
                    Some(pos) => {
                        let key = trimmed[:pos]
                        let after = strip(trimmed[pos + 1:])
                        if after == "" { YKeyOnly(indent, key) }
                        else { YKeyVal(indent, key, after) }
                    },
                    None => YListItem(indent, trimmed)
                }
            }
        }
    }
}

// --- Converter state ---

struct ConvertState {
    remaining: list<string>
}

fun make_state(input: list<string>) : ConvertState =>
    ConvertState { remaining: input }

fun current_line(st: ConvertState) : string =>
    match st.remaining {
        [line, ..rest] => line,
        [] => ""
    }

fun advance(st: ConvertState) : ConvertState =>
    match st.remaining {
        [_, ..rest] => ConvertState { remaining: rest },
        [] => st
    }

fun done(st: ConvertState) : bool =>
    match st.remaining {
        [] => true,
        _ => false
    }

fun make_pad(depth: int) : string =>
    if depth <= 0 { "" } else { "    " + make_pad(depth - 1) }

// Peek ahead to check if next line is a list item (at same or deeper indent)
fun peek_list_indent(st: ConvertState, parent_indent: int) : int {
    match st.remaining {
        [] => -1,
        [line, ..rest] => {
            let trimmed = strip(line)
            let indent = count_indent(line)
            if indent >= parent_indent {
                if has_prefix(trimmed, "- ") { indent }
                else { -1 }
            } else {
                -1
            }
        }
    }
}

// Collect list items at a given indent level into an HML array
fun collect_list_items(st: ConvertState, expected_indent: int) : (list<string>, ConvertState) {
    if done(st) { ([], st) }
    else {
        let line = current_line(st)
        let trimmed = strip(line)
        let indent = count_indent(line)
        if indent == expected_indent {
            if has_prefix(trimmed, "- ") {
                let val = strip(trimmed[2:])
                let hval = hml_value(val)
                let st2 = advance(st)
                let result = collect_list_items(st2, expected_indent)
                ([hval] + result.0, result.1)
            } else {
                ([], st)
            }
        } else {
            ([], st)
        }
    }
}

// Convert a block of YAML lines at a given indent level to HML lines
fun convert_block(st: ConvertState, parent_indent: int, depth: int) : (list<string>, ConvertState) {
    if done(st) { ([], st) }
    else {
        let line = current_line(st)
        let trimmed = strip(line)
        let indent = count_indent(line)
        // Stop if we've dedented past our parent
        if indent < parent_indent { ([], st) }
        else {
            if indent > parent_indent {
                // Skip lines with deeper indent than expected (handled by recursion)
                ([], st)
            } else {
                // We're at the expected indent level
                if trimmed == "" {
                    // Blank line — skip
                    let st2 = advance(st)
                    convert_block(st2, parent_indent, depth)
                } else {
                    if has_prefix(trimmed, "#") {
                        // Comment
                        let pad = make_pad(depth)
                        let st2 = advance(st)
                        let rest = convert_block(st2, parent_indent, depth)
                        ([pad + "//" + trimmed[1:]] + rest.0, rest.1)
                    } else {
                        if has_prefix(trimmed, "- ") {
                            // List items at top level of this block
                            let items_result = collect_list_items(st, parent_indent)
                            let items = items_result.0
                            let st2 = items_result.1
                            let arr = "[" + join(items, ", ") + "]"
                            let rest = convert_block(st2, parent_indent, depth)
                            // Return array string (caller adds key:)
                            ([arr] + rest.0, rest.1)
                        } else {
                            // Key: value or Key: (block)
                            match index_of(trimmed, ":") {
                                Some(pos) => {
                                    let key = trimmed[:pos]
                                    let hkey = to_hml_key(key)
                                    let after = strip(trimmed[pos + 1:])
                                    let pad = make_pad(depth)
                                    let st2 = advance(st)
                                    if after == "" {
                                        // Block — check if next lines are list items or a nested object
                                        let list_indent = peek_list_indent(st2, parent_indent)
                                        if list_indent >= 0 {
                                            // Collect as array
                                            let items_result = collect_list_items(st2, list_indent)
                                            let items = items_result.0
                                            let st3 = items_result.1
                                            let arr = "[" + join(items, ", ") + "]"
                                            let out_line = pad + hkey + ": " + arr
                                            let rest = convert_block(st3, parent_indent, depth)
                                            ([out_line] + rest.0, rest.1)
                                        } else {
                                            // Nested object → @element
                                            let child_indent = parent_indent + 2
                                            let body_result = convert_block(st2, child_indent, depth + 1)
                                            let body_lines = body_result.0
                                            let st3 = body_result.1
                                            let header = pad + "@" + hkey + " \{"
                                            let footer = pad + "\}"
                                            let block = [header] + body_lines + [footer]
                                            let rest = convert_block(st3, parent_indent, depth)
                                            (block + rest.0, rest.1)
                                        }
                                    } else {
                                        // Simple key: value
                                        let hval = hml_value(after)
                                        let out_line = pad + hkey + ": " + hval
                                        let rest = convert_block(st2, parent_indent, depth)
                                        ([out_line] + rest.0, rest.1)
                                    }
                                },
                                None => {
                                    // Unrecognised line, emit as comment
                                    let pad = make_pad(depth)
                                    let st2 = advance(st)
                                    let rest = convert_block(st2, parent_indent, depth)
                                    ([pad + "// ? " + trimmed] + rest.0, rest.1)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// Top-level converter
fun yaml_to_hml(input: string) : string {
    let raw_lines = lines(input)
    // Filter out empty trailing lines
    let ylines = filter(raw_lines, (l) => true)
    let st = make_state(ylines)
    let result = convert_block(st, 0, 0)
    join(result.0, "\n")
}

fun main() {
    let args = get_args()
    if length(args) == 0 {
        println("Usage: yml2hml <input.yml> [output.hml]")
        println("")
        println("Converts a YAML file to HML format.")
        println("If no output file is given, prints to stdout.")
    } else {
        let input_path = args[0]
        match read_file(input_path) {
            Ok(content) => {
                let hml_output = yaml_to_hml(content)
                if length(args) >= 2 {
                    let output_path = args[1]
                    write_file(output_path, hml_output + "\n")
                    println("Converted {input_path} -> {output_path}")
                } else {
                    println(hml_output)
                }
            },
            Err(e) => println("Error reading {input_path}: {e}")
        }
    }
}

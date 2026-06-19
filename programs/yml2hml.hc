// yml2hml.hc — Convert YAML files to HML format
//
// Usage:
//   hica run programs/yml2hml.hc -- input.yml
//   hica run programs/yml2hml.hc -- input.yml output.hml
//   hica run programs/yml2hml.hc -- --help
//
// Supports:
//   - Scalars: strings (quoted/bare), integers, floats, booleans, null
//   - Nested objects → @element blocks
//   - Scalar lists (- item) → HML arrays
//   - Lists of objects (- key: val) → repeated @elements
//   - Flow sequences: [a, b, c]
//   - Flow mappings: {key: val} → inline @element(attrs)
//   - Multi-line strings (| and >) → triple-quoted strings
//   - YAML comments (#) → HML comments (//)
//   - Inline comment stripping
//   - Underscore-to-dash key conversion
//
// Limitations:
//   - Anchors/aliases (&anchor, *alias)
//   - Complex/multi-line keys
//   - Merge keys (<<)
//   - YAML tags (!tag)

// --- YAML line classification ---
// TODO: import "../lib/hml" — re-enable when hml module is published
import "std/cli"

type YamlLine {
    YKeyVal(indent: int, key: string, text: string),
    YListItem(indent: int, text: string),
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

// Strip inline YAML comments: " # comment" at end of line
// but not inside quoted strings
fun strip_inline_comment(s: string) : string {
    let t = strip(s)
    // If value is quoted, return as-is (comment is inside quotes)
    if has_prefix(t, "'") || has_prefix(t, "\"") {
        // Find closing quote, then check for # after
        let quote_char = t[:1]
        match index_of(t[1:], quote_char) {
            Some(end_pos) => {
                let after_quote = strip(t[end_pos + 2:])
                if has_prefix(after_quote, "#") { t[:end_pos + 2] }
                else { t }
            },
            None => t
        }
    } else {
        // Unquoted: strip from first " #"
        match index_of(t, " #") {
            Some(pos) => strip(t[:pos]),
            None => t
        }
    }
}

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

// Check if value is a YAML flow sequence like [val1, val2, val3]
fun is_flow_seq(v: string) : bool =>
    has_prefix(v, "[") && ends_with(v, "]")

// Convert a YAML flow sequence to HML array
fun convert_flow_seq(v: string) : string {
    // Strip outer brackets
    let inner = strip(v[1:str_length(v) - 1])
    if inner == "" { "[]" }
    else {
        let items = split(inner, ",")
        let hml_items = map(items, (item) => hml_value(strip(item)))
        "[" + join(hml_items, ", ") + "]"
    }
}

// Check if value is a YAML flow mapping like {key: val, key: val}
fun is_flow_map(v: string) : bool =>
    has_prefix(v, "\{") && ends_with(v, "\}")

// Convert a YAML flow mapping to inline HML @element
fun convert_flow_map(v: string, key: string) : string {
    let inner = strip(v[1:str_length(v) - 1])
    if inner == "" { "@" + key }
    else {
        let pairs = split(inner, ",")
        let hml_pairs = map(pairs, (pair) => {
            let p = strip(pair)
            match index_of(p, ": ") {
                Some(i) => to_hml_key(p[:i]) + ": " + hml_value(p[i + 2:]),
                None => to_hml_key(p)
            }
        })
        "@" + key + "(" + join(hml_pairs, ", ") + ")"
    }
}

// Check if value is a YAML block scalar indicator (| or >)
fun is_block_scalar(v: string) : bool =>
    v == "|" || v == ">" || v == "|-" || v == ">-" || v == "|+" || v == ">+"

// Collect indented lines for a block scalar
fun collect_block_lines(st: ConvertState, min_indent: int) : (list<string>, ConvertState) {
    if done(st) { ([], st) }
    else {
        let line = current_line(st)
        let trimmed = strip(line)
        let indent = count_indent(line)
        // Blank lines inside block scalars are preserved
        if trimmed == "" {
            let st2 = advance(st)
            // Peek if next non-blank line is still indented
            let next_result = collect_block_lines(st2, min_indent)
            if length(next_result.0) > 0 {
                ([""] + next_result.0, next_result.1)
            } else {
                ([], st)
            }
        } else if indent >= min_indent {
            let st2 = advance(st)
            let result = collect_block_lines(st2, min_indent)
            ([trimmed] + result.0, result.1)
        } else {
            ([], st)
        }
    }
}

// Convert block scalar lines to an HML multi-line string
fun block_to_hml_string(block_lines: list<string>) : string {
    let content = join(block_lines, "\n")
    // Use HML triple-quoted multi-line string
    "\"\"\"\n" + content + "\n\"\"\""
}

fun hml_value(s: string) : string {
    let v = strip(s)
    if v == "" { "\"\"" }
    else if v == "[]" { "[]" }
    else if is_flow_seq(v) { convert_flow_seq(v) }
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

// Find key: value separator (colon followed by space or end of string)
// This avoids splitting on colons inside values like "https://..."
fun find_key_sep(s: string) : int {
    let len = str_length(s)
    find_key_sep_at(s, 0, len)
}

fun find_key_sep_at(s: string, pos: int, len: int) : int {
    if pos >= len { -1 }
    else {
        match index_of(s[pos:], ": ") {
            Some(i) => pos + i,
            None => {
                // Check if colon is at the very end (key-only)
                if str_length(s) > 0 {
                    let last = s[len - 1:]
                    if last == ":" { len - 1 }
                    else { -1 }
                } else { -1 }
            }
        }
    }
}

// Parse a single YAML line into a YamlLine
fun parse_yaml_line(line: string) : YamlLine {
    let trimmed = strip(line)
    if trimmed == "" { YBlank }
    else if has_prefix(trimmed, "#") { YComment(trimmed[1:]) }
    else {
        let indent = count_indent(line)
        if has_prefix(trimmed, "- ") {
            YListItem(indent, strip_inline_comment(strip(trimmed[2:])))
        } else {
            // Look for "key: value" (colon + space) or "key:" (colon at end)
            let sep = find_key_sep(trimmed)
            if sep >= 0 {
                let key = trimmed[:sep]
                let after = strip_inline_comment(strip(trimmed[sep + 1:]))
                if after == "" { YKeyOnly(indent, key) }
                else { YKeyVal(indent, key, after) }
            } else {
                YListItem(indent, trimmed)
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

// Collect list items at a given indent level into an HML array or repeated elements
fun collect_list_items(st: ConvertState, expected_indent: int) : (list<string>, ConvertState) {
    if done(st) { ([], st) }
    else {
        let line = current_line(st)
        let trimmed = strip(line)
        let indent = count_indent(line)
        if indent == expected_indent && has_prefix(trimmed, "- ") {
            let val = strip_inline_comment(strip(trimmed[2:]))
            // Check if this list item contains a key: value (object item)
            let sep = find_key_sep(val)
            if sep >= 0 {
                // This is a list item that starts an object — not a simple scalar
                ([], st)
            } else {
                let hval = hml_value(val)
                let st2 = advance(st)
                let result = collect_list_items(st2, expected_indent)
                ([hval] + result.0, result.1)
            }
        } else {
            ([], st)
        }
    }
}

// Collect a single object that starts with "- key: val" and continues
// with indented key: val lines below it
fun collect_object_item(st: ConvertState, dash_indent: int, depth: int) : (list<string>, ConvertState) {
    let line = current_line(st)
    let trimmed = strip(line)
    let val = strip(trimmed[2:])
    // Parse first key: val from the "- key: val" line
    let sep = find_key_sep(val)
    if sep < 0 { ([], advance(st)) }
    else {
        let key = val[:sep]
        let hkey = to_hml_key(key)
        let after = strip(val[sep + 1:])
        let pad = make_pad(depth)
        let st2 = advance(st)
        // First property from the dash line
        let first_prop = if after == "" { pad + "    " + hkey + ": \"\"" }
                        else { pad + "    " + hkey + ": " + hml_value(after) }
        // Collect continuation lines (indented deeper than the dash)
        let cont_indent = dash_indent + 2
        let body_result = convert_block(st2, cont_indent, depth + 1)
        let body_lines = body_result.0
        let st3 = body_result.1
        ([first_prop] + body_lines, st3)
    }
}

// Skip blank lines and return the next state
fun skip_blanks(st: ConvertState) : ConvertState {
    if done(st) { st }
    else {
        let line = current_line(st)
        let trimmed = strip(line)
        if trimmed == "" { skip_blanks(advance(st)) }
        else { st }
    }
}

// Collect all object items in a list-of-objects as repeated elements
fun collect_object_list(st: ConvertState, expected_indent: int, elem_name: string, depth: int) : (list<string>, ConvertState) {
    let st0 = skip_blanks(st)
    if done(st0) { ([], st0) }
    else {
        let line = current_line(st0)
        let trimmed = strip(line)
        let indent = count_indent(line)
        if indent == expected_indent && has_prefix(trimmed, "- ") {
            let pad = make_pad(depth)
            let item_result = collect_object_item(st0, expected_indent, depth)
            let item_lines = item_result.0
            let st2 = item_result.1
            let header = pad + "@" + elem_name + " \{"
            let footer = pad + "\}"
            let block = [header] + item_lines + [footer]
            let rest = collect_object_list(st2, expected_indent, elem_name, depth)
            (block + rest.0, rest.1)
        } else {
            ([], st0)
        }
    }
}

// Check if a list item is a scalar or starts an object
fun is_list_of_objects(st: ConvertState, expected_indent: int) : bool {
    match st.remaining {
        [] => false,
        [line, ..rest] => {
            let trimmed = strip(line)
            let indent = count_indent(line)
            if indent == expected_indent && has_prefix(trimmed, "- ") {
                let val = strip(trimmed[2:])
                let sep = find_key_sep(val)
                sep >= 0
            } else {
                false
            }
        }
    }
}

// Convert a YAML comment line to a HML // comment
fun convert_comment(trimmed: string, pad: string, st: ConvertState, parent_indent: int, depth: int) : (list<string>, ConvertState) {
    let comment_text = trimmed[1:]
    let spaced = if has_prefix(comment_text, " ") { comment_text } else { " " + comment_text }
    let st2 = advance(st)
    let rest = convert_block(st2, parent_indent, depth)
    ([pad + "//" + spaced] + rest.0, rest.1)
}

// Collect top-level "- item" list items and emit as an HML array
fun convert_list_line(st: ConvertState, parent_indent: int, depth: int) : (list<string>, ConvertState) {
    let items_result = collect_list_items(st, parent_indent)
    let items = items_result.0
    let st2 = items_result.1
    let arr = "[" + join(items, ", ") + "]"
    let rest = convert_block(st2, parent_indent, depth)
    ([arr] + rest.0, rest.1)
}

// Handle a block scalar value (| or >) → triple-quoted HML string
fun convert_block_scalar_key(hkey: string, pad: string, st2: ConvertState, parent_indent: int, depth: int) : (list<string>, ConvertState) {
    let block_indent = parent_indent + 2
    let block_result = collect_block_lines(st2, block_indent)
    let blines = block_result.0
    let st3 = block_result.1
    let hval = block_to_hml_string(blines)
    let out_line = pad + hkey + ": " + hval
    let rest = convert_block(st3, parent_indent, depth)
    ([out_line] + rest.0, rest.1)
}

// Handle a key with no inline value — next lines are a list or nested @element block
fun convert_nested_key(hkey: string, pad: string, st2: ConvertState, parent_indent: int, depth: int) : (list<string>, ConvertState) {
    let list_indent = peek_list_indent(st2, parent_indent)
    if list_indent >= 0 {
        if is_list_of_objects(st2, list_indent) {
            // List of objects → repeated @elements
            let obj_result = collect_object_list(st2, list_indent, hkey, depth)
            let obj_lines = obj_result.0
            let st3 = obj_result.1
            let rest = convert_block(st3, parent_indent, depth)
            (obj_lines + rest.0, rest.1)
        } else {
            // Scalar list → HML array
            let items_result = collect_list_items(st2, list_indent)
            let items = items_result.0
            let st3 = items_result.1
            let arr = "[" + join(items, ", ") + "]"
            let out_line = pad + hkey + ": " + arr
            let rest = convert_block(st3, parent_indent, depth)
            ([out_line] + rest.0, rest.1)
        }
    } else {
        // Nested object → @element block
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
}

// Handle a key with a scalar or flow-map value
fun convert_scalar_key(after: string, hkey: string, pad: string, st2: ConvertState, parent_indent: int, depth: int) : (list<string>, ConvertState) {
    if is_flow_map(after) {
        let out_line = pad + convert_flow_map(after, hkey)
        let rest = convert_block(st2, parent_indent, depth)
        ([out_line] + rest.0, rest.1)
    } else {
        let hval = hml_value(after)
        let out_line = pad + hkey + ": " + hval
        let rest = convert_block(st2, parent_indent, depth)
        ([out_line] + rest.0, rest.1)
    }
}

// Dispatch a key: value line (or emit unrecognised line as a comment)
fun convert_key(trimmed: string, pad: string, st: ConvertState, parent_indent: int, depth: int) : (list<string>, ConvertState) {
    let sep = find_key_sep(trimmed)
    if sep >= 0 {
        let key = trimmed[:sep]
        let hkey = to_hml_key(key)
        let after = strip_inline_comment(strip(trimmed[sep + 1:]))
        let st2 = advance(st)
        if is_block_scalar(after) { convert_block_scalar_key(hkey, pad, st2, parent_indent, depth) }
        else if after == "" { convert_nested_key(hkey, pad, st2, parent_indent, depth) }
        else { convert_scalar_key(after, hkey, pad, st2, parent_indent, depth) }
    } else {
        let st2 = advance(st)
        let rest = convert_block(st2, parent_indent, depth)
        ([pad + "// ? " + trimmed] + rest.0, rest.1)
    }
}

// Convert a block of YAML lines at a given indent level to HML lines
fun convert_block(st: ConvertState, parent_indent: int, depth: int) : (list<string>, ConvertState) {
    if done(st) { ([], st) }
    else {
        let line = current_line(st)
        let trimmed = strip(line)
        let indent = count_indent(line)
        if indent < parent_indent { ([], st) }
        else if indent > parent_indent { ([], st) }
        else if trimmed == "" { convert_block(advance(st), parent_indent, depth) }
        else {
            let pad = make_pad(depth)
            if has_prefix(trimmed, "#") { convert_comment(trimmed, pad, st, parent_indent, depth) }
            else if has_prefix(trimmed, "- ") { convert_list_line(st, parent_indent, depth) }
            else { convert_key(trimmed, pad, st, parent_indent, depth) }
        }
    }
}

// Top-level converter
fun yaml_to_hml(input: string) : string {
    let raw_lines = lines(input)
    // Filter out empty trailing lines
    let st = make_state(raw_lines)
    let result = convert_block(st, 0, 0)
    join(result.0, "\n")
}

fun make_spec() =>
    cli("yml2hml", "1.0.0", "convert YAML files to HML format")
        |> arg("input", "YAML file to convert", true)
        |> arg("output", "output HML file (default: stdout)", false)

fun convert(r) {
    let input_path = r.cli_positionals[0]
    match read_file(input_path) {
        Ok(content) => {
            let hml_output = yaml_to_hml(content)
            match get_positional(r, 1) {
                Some(output_path) => {
                    write_file(output_path, hml_output + "\n")
                    println("Converted {input_path} -> {output_path}")
                },
                None => println(hml_output)
            }
        },
        Err(e) => eprintln("error: could not read {input_path}: {e}")
    }
}

fun main() {
    let spec = make_spec()
    match cli_parse(spec) {
        Help          => println(cli_help(spec)),
        Version       => println(cli_version_str(spec)),
        CliError(msg) => eprintln("error: {msg}"),
        Parsed(r)     => convert(r)
    }
}
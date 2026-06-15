---
layout: default
title: Libraries - hica
---

# Libraries

hica libraries are currently distributed as git submodules while the package registry and dependency manager are under development.

## Installation

Add a library as a git submodule to your project:

```sh
git submodule add https://github.com/cladam/yaml.git lib/yaml
```

Then import it in your hica source:

```hica
import "./lib/yaml/src/yaml"
```

Libraries in hica are imported directly from source paths.

## Available Libraries

### Data Formats

#### yaml

A YAML parser and serializer for hica. Parses the YAML that real-world config files use: maps, lists, scalars, comments, multi-document streams, anchors & aliases, and block/flow styles. Emit valid YAML back with `yaml_emit` (block-style) or `yaml_emit_flow` (compact).

- **Repository**: [github.com/cladam/yaml](https://github.com/cladam/yaml)
- **Version**: v1.0.0
- **Install**: `git submodule add https://github.com/cladam/yaml.git lib/yaml`
- **Import**: `import "./lib/yaml/src/yaml"`

```hica
import "./lib/yaml/src/yaml"

fun main() {
  let input = "database:\n  host: localhost\n  port: 5432"

  // Parse and navigate with pipes
  let host = yaml_parse(input)
    |> yaml_ok
    |> at("database")
    |> at("host")
    |> as_str

  println(str_or(host, "unknown"))

  // Serialize back to YAML
  let data = YMap([("name", YStr("myapp")), ("port", YInt(8080))])
  println(yaml_emit(data))
}
```

#### toml

A full TOML v1.1.0 parser for hica. Handles all TOML types including date-times, inline tables, arrays of tables, and unicode escapes. Error messages include line numbers.

- **Repository**: [github.com/cladam/toml](https://github.com/cladam/toml)
- **Version**: v1.0.0
- **Install**: `git submodule add https://github.com/cladam/toml.git lib/toml`
- **Import**: `import "./lib/toml/src/toml"`

```hica
import "./lib/toml/src/toml"

fun main() {
  let input = "[server]\nhost = \"localhost\"\nport = 8080"

  // Parse and navigate with pipe notation
  let doc = toml_ok(toml_parse(input))
  let host = doc |> at("server") |> at("host").as_str

  println(str_or(host, "unknown"))
}
```

#### hml

An HML (Hica Markup Language) parser. HML combines the semantic strength of XML (elements with identity and metadata) with the readability of TOML/YAML. Supports dotted keys, namespaces, `#include` directives, durations, date-times, and merge rule validation.

- **Repository**: [github.com/cladam/hml](https://github.com/cladam/hml)
- **Version**: v1.0.0
- **Install**: `git submodule add https://github.com/cladam/hml.git lib/hml`
- **Import**: `import "./lib/hml/src/hml"`

```hica
import "./lib/hml/src/hml"

fun main() {
  let input = "@server(port: 8080) {\n  host: \"localhost\"\n}"

  let nodes = hml_ok(hml_parse(input))
  let srv = nodes |> elem_at("server")
  let host = srv |> hml_body |> at("host") |> as_str

  println(str_or(host, "unknown"))
}
```

#### csv

An RFC 4180 CSV parser and serializer for hica. Parses comma-separated and delimiter-separated text into typed `CsvTable` values with named column access, filtering, mapping, and round-trip serialization. Supports quoted fields, embedded delimiters, doubled-quote escaping, custom delimiters (TSV, semicolon), optional header rows, and `\n`/`\r\n`/`\r` line endings.

- **Repository**: [github.com/cladam/csv](https://github.com/cladam/csv)
- **Version**: v1.0.0
- **Install**: `git submodule add https://github.com/cladam/csv.git lib/csv`
- **Import**: `import "./lib/csv/src/csv"`

```hica
import "./lib/csv/src/csv"

fun main() {
  let input = "name,age,city\nKalle,30,Copenhagenk\nLisa,25,Stockholm"
  let t = csv_parse(input)

  println(csv_pretty(t))
  // name  | age | city    
  // ------+-----+---------
  // Kalle | 30  | Copenhagen
  // Lisa  | 25  | Stockholm  

  match csv_get_by_name(t, 1, "city") {
    Some(v) => println(v),   // Stockholm
    None => println("not found")
  }

  // Tab-separated, no header
  let opts = CsvOptions { delimiter: "\t", has_header: false, quote_char: "\"" }
  let tsv = csv_parse_opts("1\thello\n2\tworld", opts)
  println(csv_show(tsv))  // [csv: 2 rows x 2 cols]

  // Round-trip
  println(csv_to_csv(t))
}
```

#### json

A JSON parser and serializer for hica. Parses any valid JSON — null, booleans, numbers, strings, arrays, and objects including nested structures and unicode escapes — and provides a pipe-friendly API for navigating and extracting values.

- **Repository**: [github.com/cladam/json](https://github.com/cladam/json)
- **Version**: v1.0.0
- **Install**: `git submodule add https://github.com/cladam/json.git lib/json`
- **Import**: `import "./lib/json/src/json"`

```hica
import "./lib/json/src/json"

fun main() {
  let input = "{\"database\": {\"host\": \"localhost\", \"port\": 5432}}"

  // Parse and navigate with pipes
  let host = parse_json(input)
    |> json_ok
    |> at("database")
    |> at("host")
    |> as_str

  println(str_or(host, "unknown"))

  // Serialize back to JSON
  let data = JObject([("name", JString("myapp")), ("port", JNumber(8080.0))])
  println(json_emit(data))
  // {"name": "myapp", "port": 8080.0}

  println(json_pretty(data, 0))
  // {
  //   "name": "myapp",
  //   "port": 8080.0
  // }
}
```

**Navigation API** (`parse_json` returns `result<Json, string>`; use `json_ok` to get `maybe<Json>`):

| Function | Purpose |
|----------|---------|
| `json_ok` | Convert parse result to `maybe<Json>` |
| `at(key)` | Navigate into an object field |
| `nth(i)` | Index into an array |
| `as_str` | Extract string value |
| `as_int` | Extract int value (truncates float) |
| `as_num` | Extract number as float |
| `as_bool` | Extract bool value |
| `as_array` | Extract array items |
| `as_object` | Extract object fields |

**Defaults**: `str_or`, `int_or`, `num_or`, `bool_or` — unwrap a `maybe<Json>` with a fallback value.

**Inspection**: `has_key`, `keys`, `json_length`.

**Direct accessors** (for unwrapped `Json`): `json_get`, `json_str`, `json_int`, `json_num`, `json_bool`, `json_array`, `json_object`, `json_is_null`.

### Networking

#### http

HTTP client library built on libcurl. Supports GET, POST, PUT, DELETE, PATCH, HEAD with timeouts, JSON helpers, URL building with query parameters, header parsing, and auth helpers (Bearer, Basic). Requires libcurl on the system.

- **Repository**: [github.com/cladam/http](https://github.com/cladam/http)
- **Version**: v1.0.0
- **Requires**: libcurl, Koka 3.2.3+, hica 0.16.0+
- **Install**: `git submodule add https://github.com/cladam/http.git lib/http`
- **Import**: `extern import "http"` + `import http_client`

```hica
extern import "http"
import http_client

fun main() {
  // Simple GET
  let resp = http_get("https://httpbin.org/get", timeout=10)
  println("Status: " + show(resp.status))
  println("OK? " + show(is_ok(resp)))

  // Parse response headers
  let content_type = find_header(resp.headers, "Content-Type")
  println("Content-Type: " + content_type)

  // JSON POST
  let post_resp = json_post("https://httpbin.org/post", "{\"hello\":\"world\"}")
  println("Post status: " + show(post_resp.status))
}
```

Note: `http` is a Koka library (C FFI), so it uses `extern import` instead of a regular hica import. Configure your `hica.hml` with `flags: "--cclib=curl"` under `@koka { ... }`.

### Text Processing

#### base64

Base64 encoding and decoding for hica. Pure functions with no effects, encode strings to standard base64 (RFC 4648) with padding, or URL-safe base64 without padding. Decoding returns `result<string, string>` for clean error handling.

- **Repository**: [github.com/cladam/base64](https://github.com/cladam/base64)
- **Version**: v1.0.1
- **Install**: `git submodule add https://github.com/cladam/base64.git lib/base64`
- **Import**: `import "./lib/base64/src/base64"`

```hica
import "./lib/base64/src/base64"

fun main() {
  let encoded = b64_encode("Hello, World!")
  println(encoded)  // SGVsbG8sIFdvcmxkIQ==

  match b64_decode(encoded) {
    Ok(text) => println(text),  // Hello, World!
    Err(e) => println("Error: " + e)
  }

  // URL-safe encoding (no padding, uses - and _ instead of + and /)
  let url = b64_encode_url("Hello, World!")
  println(url)  // SGVsbG8sIFdvcmxkIQ
}
```

### GUI

#### imgui

An immediate-mode GUI library for hica, backed by [Dear ImGui](https://github.com/ocornut/imgui) + SDL2 + OpenGL3. Ships with the Inter font and the Ilseon dark theme baked in. Build native desktop GUIs with no external assets.

- **Repository**: [github.com/cladam/imgui](https://github.com/cladam/imgui)
- **Requires**: SDL2 on the system (`brew install sdl2` / `apt install libsdl2-dev`)
- **Install**: `git submodule add https://github.com/cladam/imgui.git lib/imgui`
- **Import**: `import "../../lib/imgui/src/imgui"` (path relative to your source file)

**Step 1 — download the pre-built static library:**

```sh
mkdir -p lib/imgui/lib

# macOS Apple Silicon:
curl -L https://github.com/cladam/imgui/releases/latest/download/libimgui_hica-macos-arm64.a \
     -o lib/imgui/lib/libimgui_hica.a

# Linux x86-64:
# curl -L https://github.com/cladam/imgui/releases/latest/download/libimgui_hica-linux-x86_64.a \
#      -o lib/imgui/lib/libimgui_hica.a
```

Or build from source with `cd lib/imgui && ./build.sh` (requires clang++ and SDL2 dev headers).

**Step 2 — configure `hica.hml`:**

```hml
@koka {
    include: "./lib/imgui/src"
    flags: "--cclinkopts=-L./lib/imgui/lib --cclinkopts=-L/opt/homebrew/opt/sdl2/lib --cclib=imgui_hica --cclib=SDL2 --cclinkopts=-lc++ --cclinkopts=-framework --cclinkopts=OpenGL"
}
```

Run `sdl2-config --libs` to find the correct SDL2 lib path on your machine. Linux users replace the last two flags with `--cclib=GL`.

**Quick start:**

```hica
import "../../lib/imgui/src/imgui"

fun main() {
  var count = 0

  gui_window("My App", 520, 360, () => {
    gui_text("Counter: " + show(count))
    if gui_button("Increment") {
      count = count + 1
    }
  })
}
```

`gui_window` opens the OS window, runs the render loop, and calls your lambda every frame. Close the window to exit.

See [examples/hello-gui](https://github.com/cladam/imgui/tree/main/examples/hello-gui) for a full widget showcase.
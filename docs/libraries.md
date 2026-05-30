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

Note: `http` is a Koka library (C FFI), so it uses `extern import` instead of a regular hica import. Configure your `hica.ini` with `flags = --cclib=curl` under `[koka]`.

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
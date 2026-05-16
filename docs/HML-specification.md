---
layout: default
title: HML Specification - hica
---

# HML v0.3.0 (2026-05-16)

Hica Markup Language.

By Claes Adamsson, et al.

## Objectives

HML aims to be a structured document and configuration language that preserves
the semantic distinction between identity/metadata and structural content (the
core strength of XML) while eliminating visual noise. HML should be readable at
a glance, parseable without ambiguity, and mappable to both tree structures and
hash tables.

## Spec

- HML is case-sensitive.
- An HML file must be a valid UTF-8 encoded Unicode document.
- Whitespace means tab (0x09) or space (0x20).
- Newline means LF (0x0A) or CRLF (0x0D 0x0A).
- Indentation is treated as whitespace and ignored by the parser (but encouraged
  for readability).

## Comment

A double slash marks the rest of the line as a comment, except when inside a
string.

```
// This is a full-line comment
@server(port: 8080) {  // This is an inline comment
    name: "api"
}
```

Control characters other than tab (U+0000 to U+0008, U+000A to U+001F, U+007F)
are not permitted in comments.

## Document Structure

An HML document is a sequence of zero or more **elements** and/or **properties**
at the top level. The root of the document is an implicit anonymous element.

```
// Top-level properties
version: "1.0"

// Top-level elements
@server(port: 8080) {
    name: "api"
}
```

## Element

An element is the primary structural unit of HML. It represents a named node in
the document tree. Elements begin with the `@` sigil followed by a name.

An element may have:
- **Attributes**: metadata in parentheses `(...)`
- **Body**: content in braces `{...}`
- Both, or neither.

```
// Element with attributes only (self-closing)
@break
@node(id: "n1", status: "healthy")

// Element with body only
@content {
    text: "hello"
}

// Element with both attributes and body
@user(id: "usr_42", active: true) {
    name: "Alex"
    role: "Admin"
}
```

An element without a body and without attributes is a **bare element**. An
element without a body but with attributes is a **leaf element**. Both are
analogous to XML's self-closing tags.

### Element Names

Element names follow the same rules as bare keys (see Keys below). Namespaced
names use dot-notation:

```
@k8s.pod(name: "worker") {
    @hica.limits {
        timeout: 10s
    }
}
```

## Attribute

Attributes are key-value pairs enclosed in parentheses after the element name.
They represent the **identity and metadata** of an element: information that
describes *what* the element is rather than *what it contains*.

```
@service(id: "auth-api", public: true, version: 3)
```

Attributes are comma-separated. Trailing commas are permitted. Values follow the
same type rules as property values (see Values below).

```
// Trailing comma is valid
@node(
    id: "n1",
    region: "eu-west",
    weight: 1.5,
)
```

Attributes without a value are **boolean flags** that default to `true`:

```
@field(required, unique) {
    name: "email"
    type: "string"
}
// `required` is shorthand for `required: true`
```

## Property

A property is a key-value pair within an element body. Properties represent the
**content** of an element, i.e. the data it holds.

```
@database {
    host: "localhost"
    port: 5432
    ssl: true
    connection_timeout: 30s
}
```

Properties are separated by newlines. A property consists of a key, a colon, and
a value. Whitespace around the colon is ignored.

Multiple properties on the same line are invalid:

```
// INVALID
@config {
    host: "localhost" port: 5432
}
```

## Keys

Keys may be bare, quoted, or dotted.

**Bare keys** may contain ASCII letters, ASCII digits, underscores, and dashes
(`A-Za-z0-9_-`).

```
@server {
    host: "localhost"
    max-connections: 100
    retry_count: 3
}
```

**Quoted keys** allow broader character sets:

```
@translations {
    "en-US": "Hello"
    "日本語": "こんにちは"
    "key with spaces": "value"
}
```

**Dotted keys** create nested structure inline:

```
@config {
    database.host: "localhost"
    database.port: 5432
}
// Equivalent to:
@config {
    @database {
        host: "localhost"
        port: 5432
    }
}
```

**Limitation:** A dotted key creates an implicit element that cannot accept
attributes. If an element later requires attributes (e.g., an `id`), the dotted
key must be refactored to explicit `@element(...)` syntax. This is an intentional
tradeoff: dotted keys optimise for brevity in flat configuration, not for
full element expressiveness.

**Merge rule:** Dotted keys and explicit elements for the same name within the
same scope must not coexist. The following is invalid:

```
// INVALID: cannot mix dotted keys with explicit element for same name
@config {
    database.host: "localhost"
    @database {
        port: 5432
    }
}
```

Use one form or the other, not both.

## Values

Every property value or attribute value must be one of the following types:

- String
- Integer
- Float
- Boolean
- Duration
- Date-Time
- Array
- Inline Element
- Null

## String

There are four ways to express strings: basic, multi-line basic, literal, and
multi-line literal.

**Basic strings** are surrounded by quotation marks (`"`).

```
str: "I'm a string. \"You can quote me\"."
```

Escape sequences:

```
\b         - backspace       (U+0008)
\t         - tab             (U+0009)
\n         - linefeed        (U+000A)
\f         - form feed       (U+000C)
\r         - carriage return (U+000D)
\"         - quote           (U+0022)
\\         - backslash       (U+005C)
\uXXXX     - unicode         (U+XXXX)
\UXXXXXXXX - unicode         (U+XXXXXXXX)
```

**Multi-line basic strings** are surrounded by three quotation marks:

```
description: """
    This is a multi-line string.
    Leading whitespace is preserved.
    """
```

A newline immediately following the opening `"""` is trimmed.

**Literal strings** are surrounded by single quotes and allow no escaping:

```
regex: '<\i\c*\s*>'
winpath: 'C:\Users\docs'
```

**Multi-line literal strings** are surrounded by three single quotes:

```
template: '''
    No escaping here: \n is literal.
    Good for regex or templates.
    '''
```

## Integer

```
int1: 42
int2: +99
int3: -17
int4: 1_000_000
int5: 0xDEADBEEF
int6: 0o755
int7: 0b11010110
```

## Float

```
flt1: 3.14
flt2: -0.01
flt3: 5e+22
flt4: 6.626e-34
flt5: inf
flt6: -inf
flt7: nan
```

## Boolean

```
enabled: true
verbose: false
```

## Duration

HML natively supports duration literals, common in configuration:

```
timeout: 30s
interval: 500ms
ttl: 24h
grace_period: 5m
```

Valid duration suffixes:

```
ns   - nanoseconds
us   - microseconds
ms   - milliseconds
s    - seconds
m    - minutes
h    - hours
d    - days
```

Zero durations are valid (e.g., `0s`, `0ms`).

Compound durations are not supported. Use the smallest needed unit:

```
// VALID
timeout: 90s
no_delay: 0s

// INVALID
timeout: 1m30s
```

## Date-Time

HML uses RFC 3339 formatted date-times:

```
created: 2024-05-27T07:32:00Z
modified: 2024-05-27T00:32:00-07:00
date_only: 2024-05-27
time_only: 07:32:00
```

## Null

An explicit null value:

```
@config {
    override: null
}
```

## Array

Arrays are square brackets with comma-separated values:

```
ports: [8080, 8081, 8082]
tags: ["web", "production", "v2"]
matrix: [[1, 2], [3, 4]]
```

Arrays may span multiple lines with optional trailing commas:

```
allowed_hosts: [
    "localhost",
    "api.example.com",
    "*.internal",
]
```

## Inline Element

An element may appear as a value in a property or attribute. This is the
equivalent of TOML's inline tables:

```
@upstream(url: "https://api.internal") {
    retry: @policy(max: 3, delay: 500ms)
}
```

Inline elements follow the same rules as block elements but must appear on a
single line when used as a value:

```
primary: @endpoint(url: "https://a.example.com", weight: 10)
fallback: @endpoint(url: "https://b.example.com", weight: 1)
```

## Repeated Elements (Lists)

Multiple elements with the same name within a body form an implicit array,
analogous to repeated XML elements:

```
@cluster(region: "eu-west") {
    @node(id: "n1", status: "healthy")
    @node(id: "n2", status: "draining")
    @node(id: "n3", status: "healthy")
}
```

This maps to:

```json
{
  "cluster": {
    "@region": "eu-west",
    "node": [
      { "@id": "n1", "@status": "healthy" },
      { "@id": "n2", "@status": "draining" },
      { "@id": "n3", "@status": "healthy" }
    ]
  }
}
```

## Text Content (Mixed Content)

Text content requires an **explicit wrapper element**; it is not allowed
implicitly in any element body. This prevents ambiguity where a typo in a
property key (e.g., forgetting a colon: `timeout 30s`) would silently parse as
text instead of raising a syntax error.

### Built-in Text Elements

The following element names are built-in text-mode elements:

- `@body`: general prose container
- `@p`: paragraph
- `@text`: inline text span

Additional text elements may be declared via the `#text` directive:

```
#text: section, aside, caption
```

When a schema language is available, schemas may also designate elements as
text-mode. In the absence of both a `#text` directive and a schema, only the
three built-in names are valid text containers.

### Text Mode Behaviour

Text elements switch the parser into text mode within their braces. Inline
elements within text are delimited with the short form `@name{content}`:

```
@article(category: "engineering") {
    title: "On Code Stillness"

    @body {
        This is a paragraph explaining the philosophy of HML.
        We can embed @em{inline emphasis} or even a
        @link(href: "https://hica.dev"){hyperlink} seamlessly.

        @p {
            A new paragraph can be explicitly marked.
        }
    }
}
```

Text content rules:
- Text content is only valid inside text-mode elements (built-in or declared via
  `#text` directive or schema).
- A line that matches `key: value` inside a text element is still parsed as a
  property. To include a literal colon in text, no special escaping is needed;
  the parser only treats it as a property if the left side is a valid key token.
- Inline elements use the compact form: `@name{text}` or `@name(attrs){text}`
  (no space before the brace).
- A blank line separates paragraphs.
- Leading/trailing whitespace in text blocks is trimmed per-line.

## Namespaces

Namespaces prevent naming collisions when multiple systems share a document.
They use dot-notation in element names:

```
@k8s.deployment(name: "api") {
    replicas: 3

    @k8s.container(name: "app", image: "myapp:latest") {
        @hica.probe(type: "liveness") {
            path: "/health"
            interval: 10s
        }
    }
}
```

A namespace declaration at the top of the document can establish short prefixes:

```
#namespace k8s: "https://kubernetes.io/schema/v1"
#namespace hica: "https://hica.dev/schema/v1"
```

## Directives

Lines beginning with `#` (outside strings) are **directives**, file-level
metadata that instructs parsers and tooling:

```
#hml 0.3
#schema: "https://hica.dev/schemas/component.hml"
#encoding: "utf-8"
#namespace k8s: "https://kubernetes.io/schema/v1"
```

Directives must appear before any elements or properties, with the exception of
`#include` which may appear anywhere in the document (see below).

### Required Directives

None. All directives are optional.

### Standard Directives

| Directive    | Purpose                                      |
|-------------|----------------------------------------------|
| `#hml`      | Declares the HML version                     |
| `#schema`   | Points to a validation schema                |
| `#encoding` | Declares character encoding (default: UTF-8) |
| `#namespace`| Declares a namespace prefix binding          |
| `#text`     | Declares additional text-mode element names   |
| `#include`  | Includes another HML file at point of insertion |

### The `#include` Directive

For large configuration environments, splitting definitions across multiple files
is a necessity. The `#include` directive makes file composition native:

```
#include "database.hml"
#include "services.hml"

@app {
    name: "main"
}
```

Semantics:
- `#include` textually inserts the target file's elements and properties into
  the current scope at the point of insertion.
- Included files are resolved relative to the including file's directory.
- Circular includes are a parse error.
- Included files must be valid HML documents (they may contain their own
  directives, which are processed in the included file's context).

## Schema Language (Future)

HML schemas define the valid structure of a document. Schema design is deferred
to a future version but will support:

- Element and property type constraints
- Required/optional markers
- Cardinality (min/max occurrences)
- Enum value restrictions
- Pattern validation for strings
- Duration range validation

## Filename Extension

HML files should use the extension `.hml`.

## MIME Type

When transferring HML files over the internet, the appropriate MIME type is
`application/hml`.

## Comparison with Other Formats

### XML Equivalent

XML:
```xml
<service id="auth-api" public="true">
    <environment>production</environment>
    <upstream url="https://api.internal">
        <retry max="3" delay="500ms" />
    </upstream>
</service>
```

HML:
```
@service(id: "auth-api", public: true) {
    environment: "production"

    @upstream(url: "https://api.internal") {
        retry: @policy(max: 3, delay: 500ms)
    }
}
```

### JSON Mapping Convention

When mapping HML to JSON, attributes are distinguished from properties by
prefixing their keys with `@`. This convention is **informational**; tooling
may use alternative mappings (e.g., a separate `"_attrs"` object), but the `@`
prefix is the recommended default for interoperability:

```json
{
  "service": {
    "@id": "auth-api",
    "@public": true,
    "environment": "production",
    "upstream": {
      "@url": "https://api.internal",
      "retry": { "@max": 3, "@delay": "500ms" }
    }
  }
}
```

## Design Principles

1. **Metadata vs. Content.** Attributes `(...)` hold identity; bodies `{...}`
   hold substance. This distinction is enforced by syntax, not convention.

2. **Low Visual Noise.** No closing tags, no angle brackets, no redundant
   punctuation. The `@` sigil is the only structural marker needed.

3. **Vertical Readability.** Brace alignment creates natural visual hierarchy.
   The eye follows structure downward without scanning for matching end-tags.

4. **Progressive Complexity.** Simple configs look like key-value files. Rich
   documents add elements and text. The syntax scales without mode-switching.

5. **Unambiguous Parsing.** The `@` sigil always introduces structure. The
   parser never needs lookahead beyond a single token to determine context.

## ABNF Grammar

```abnf
; HML v0.3.0 Grammar

document       = *directive *(element / property / comment / newline)

directive      = "#" directive-name [ ":" ws directive-value ] newline
directive-name = 1*ALPHA
directive-value = *non-newline

element        = "@" element-name [attributes] [body]
element-name   = bare-key *("." bare-key)

attributes     = "(" [attr-list] ")"
attr-list      = attribute *("," attribute) [","]
attribute      = key [":" ws scalar-value]

scalar-value   = string / integer / float / boolean / duration
               / date-time / null

body           = "{" body-content "}"
body-content   = *(element / property / comment / newline)

text-body      = "{" text-body-content "}"
text-body-content = *(text-content / element / property / comment / newline)
; text-body is used for text-mode elements (built-in or #text-declared).
; Regular body does NOT permit text-content.

property       = key ":" ws value newline
; NOTE: Property takes precedence over text-content in text-body.
; A line matching key ":" ws value is always a property, never text.

key            = bare-key / quoted-key / dotted-key
bare-key       = 1*(ALPHA / DIGIT / "_" / "-")
quoted-key     = basic-string / literal-string
dotted-key     = key 1*("." key)

value          = string / integer / float / boolean / duration
               / date-time / array / null / inline-element

inline-element = "@" element-name [attributes] [inline-body]
inline-body    = "{" inline-text "}"  ; strictly single-line, no newlines
inline-text    = *(text-char / inline-element)  ; no newline permitted

string         = basic-string / ml-basic-string
               / literal-string / ml-literal-string
basic-string   = DQUOTE *basic-char DQUOTE
ml-basic-string = 3DQUOTE [newline] *ml-basic-char 3DQUOTE
literal-string = "'" *literal-char "'"
ml-literal-string = "'''" [newline] *ml-literal-char "'''"

integer        = [sign] digits
               / "0x" hex-digits
               / "0o" oct-digits
               / "0b" bin-digits

float          = [sign] digits "." digits [exponent]
               / [sign] digits exponent
               / [sign] ("inf" / "nan")

boolean        = "true" / "false"

duration       = digits duration-unit
duration-unit  = "ns" / "us" / "ms" / "s" / "m" / "h" / "d"

array          = "[" [array-values] "]"
array-values   = value *("," value) [","]

null           = "null"

text-content   = 1*text-char *(inline-element 1*text-char)
text-char      = %x20-3F / %x41-5A / %x5C / %x5E-7A / %x7C / %x7E-7F
               / UTF8-non-ascii
               ; any printable character except @ (0x40), { (0x7B), } (0x7D)

comment        = "//" *non-newline newline

ws             = *(" " / %x09)
newline        = %x0A / %x0D.0A
non-newline    = %x09 / %x20-7E / UTF8-non-ascii
sign           = "+" / "-"
digits         = DIGIT *("_" DIGIT)
```

## Design Decisions (Resolved)

The following questions from v0.1.0 have been resolved:

**Text content requires an explicit wrapper element.** Implicit text in any
element body creates parser ambiguity (a typo like `timeout 30s` silently
becomes text). Requiring `@body{...}`, `@p{...}`, or similar preserves the
predictability and safety of a configuration language.

**Attributes are strictly scalar.** Attribute values may only be primitives
(strings, numbers, booleans, durations, dates, null). Arrays and nested elements
belong in the element body `{...}`. This keeps the `(...)` block inline,
scannable, and compact.

**No CDATA-equivalent.** Multi-line literal strings (`'''...'''`) already fill
this role by allowing unescaped raw text without breaking the parser. A separate
CDATA construct would add unnecessary syntactic noise.

**`#include` is a standard directive.** See the `#include` section above.

**Property order is preserved but not semantically significant.** Parsers must
maintain insertion order when serialising or iterating properties (matching the
behaviour users expect from JSON objects and TOML tables). However, two documents
with the same properties in different order are considered equivalent for
validation and comparison purposes.

## Open Questions

- Should HML support a streaming/event-based parse mode for very large documents?
- Should there be a canonical serialisation form for diffing and signing?

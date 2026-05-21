module repl-docs

// ---------------------------------------------------------------------------
// REPL inline documentation — :doc command
// Concise reference accessible without leaving the REPL.
// ---------------------------------------------------------------------------

pub fun doc-topic-names() : list<string>
  doc-topics().map(fn((name, _)) name)

pub fun lookup-doc( query : string ) : maybe<string>
  val q = query.to-lower.trim
  // Try topic first
  match doc-topics().filter(fn((name, _)) name == q)
    Cons((_, text), _) -> Just(text)
    _ -> // Try function docs
      match doc-funs().filter(fn((name, _, _)) name == q)
        Cons((name, sig, desc), _) -> Just("  " ++ name ++ "\n  " ++ sig ++ "\n\n  " ++ desc)
        _ -> Nothing

pub fun doc-topic-list() : string
  val topics = doc-topics().map(fn((name, _)) name)
  val fns = doc-funs().map(fn((name, _, _)) name)
  "Topics:\n  " ++ topics.join(", ") ++ "\n\nFunctions (use :doc <name>):\n  " ++ fns.take(20).join(", ") ++ ", ..."

// ---------------------------------------------------------------------------
// Language topics — concise REPL-sized help
// ---------------------------------------------------------------------------

fun doc-topics() : list<(string, string)>
  [ ("functions", doc-functions-topic())
  , ("match", doc-match-topic())
  , ("pipe", doc-pipe-topic())
  , ("lists", doc-lists-topic())
  , ("structs", doc-structs-topic())
  , ("enums", doc-enums-topic())
  , ("loops", doc-loops-topic())
  , ("strings", doc-strings-topic())
  , ("modules", doc-modules-topic())
  , ("variables", doc-variables-topic())
  , ("maybe", doc-maybe-topic())
  , ("result", doc-result-topic())
  , ("testing", doc-testing-topic())
  , ("operators", doc-operators-topic())
  ]

fun doc-functions-topic() : string
  [ "  Functions"
  , ""
  , "  fun name(params) { body }       — named function"
  , "  fun name(params) => expr        — expression-bodied (arrow syntax)"
  , "  fun name(a: int) : string => .. — with type annotations"
  , "  pub fun name(...) => ...        — public (exported from module)"
  , "  let f = (x) => x * 2           — lambda / closure"
  , ""
  , "  The last expression is the return value. No 'return' needed."
  , "  Type annotations are optional — types are inferred."
  , ""
  , "  Example:"
  , "    fun greet(name: string) : string => \"Hello, \" + name"
  ].join("\n")

fun doc-match-topic() : string
  [ "  Pattern Matching"
  , ""
  , "  match value {"
  , "    pattern => result,"
  , "    ...    "
  , "  }"
  , ""
  , "  Patterns: literals, _, x (bind), (a, b) (tuple),"
  , "    [x, ..rest] (list), StructName { field } (struct),"
  , "    Variant(x) (enum), x if cond (guard), p1 | p2 (or)"
  , ""
  , "  Range:  0..=59 => \"F\"          — inclusive range"
  , "  Bit:    0b11??_???? => \"cat 3\"  — ? = don't-care bit"
  , ""
  , "  Examples:"
  , "    match xs {"
  , "      []          => \"empty\","
  , "      [x, ..rest] => \"head is {x}\""
  , "    }"
  , ""
  , "    match point {"
  , "      (0, 0) => \"origin\","
  , "      (x, y) => \"({x}, {y})\""
  , "    }"
  ].join("\n")

fun doc-pipe-topic() : string
  [ "  Pipe & Dot-call"
  , ""
  , "  |>  Pipe: passes left side as first argument to right side"
  , "  .   Dot-call (UFCS): a.f(b) desugars to f(a, b)"
  , ""
  , "  Both are equivalent ways to chain calls left-to-right:"
  , "    5 |> double |> add_one          — pipe style"
  , "    5.double().add_one()            — dot-call style"
  , "    [1,2,3].filter((x) => x > 1)   — dot-call with args"
  , ""
  , "  Rule: expr.name without () is struct field access."
  , "        expr.name(...) with () is a function call."
  ].join("\n")

fun doc-lists-topic() : string
  [ "  Lists"
  , ""
  , "  let xs = [1, 2, 3]              — list literal"
  , "  let empty = []                   — empty list"
  , ""
  , "  Common operations (all pipe-friendly):"
  , "    xs |> length                   — number of elements"
  , "    xs |> map((x) => x * 2)       — transform each element"
  , "    xs |> filter((x) => x > 1)    — keep matching elements"
  , "    xs |> head                     — first element (maybe)"
  , "    xs |> tail                     — all but first"
  , "    xs |> take(2)                  — first N elements"
  , "    xs |> drop(2)                  — skip first N"
  , "    xs |> reverse                  — reverse the list"
  , "    xs |> zip_with(ys, f)         — combine two lists"
  , "    xs |> foldl(0, (acc, x) => acc + x) — reduce"
  , ""
  , "  Pattern match on lists:"
  , "    match xs {"
  , "      []          => \"empty\","
  , "      [x, ..rest] => \"starts with {x}\""
  , "    }"
  ].join("\n")

fun doc-structs-topic() : string
  [ "  Structs"
  , ""
  , "  struct Point { x: int, y: int }"
  , ""
  , "  let p = Point { x: 3, y: 4 }   — construct"
  , "  p.x                             — field access"
  , "  Point { ...p, x: 10 }           — update (copy with changes)"
  , ""
  , "  Struct names must start with an uppercase letter."
  , "  Fields are accessed with dot notation."
  , "  Structs are immutable — update creates a new value."
  , ""
  , "  Pattern match:"
  , "    match p {"
  , "      Point { x: 0, y: 0 } => \"origin\","
  , "      Point { x, y }       => \"({x}, {y})\""
  , "    }"
  ].join("\n")

fun doc-enums-topic() : string
  [ "  Enums (Algebraic Types)"
  , ""
  , "  type Shape {"
  , "    Circle(radius: float),"
  , "    Rect(width: float, height: float),"
  , "    Point"
  , "  }"
  , ""
  , "  let s = Circle(5.0)             — construct"
  , ""
  , "  Pattern match to handle variants:"
  , "    match s {"
  , "      Circle(r)  => \"radius {r}\","
  , "      Rect(w, h) => \"{w} x {h}\","
  , "      Point      => \"a point\""
  , "    }"
  , ""
  , "  Enum vs Struct:"
  , "    struct = AND of fields (every value has all fields)"
  , "    enum   = OR of variants (each value is one alternative)"
  ].join("\n")

fun doc-loops-topic() : string
  [ "  Loops"
  , ""
  , "  for i in 0..10 { ... }          — range loop (0 to 9)"
  , "  for x in xs { ... }             — collection loop"
  , "  while cond { ... }              — condition loop"
  , "  repeat(n) { ... }               — fixed repetitions"
  , "  loop { ... }                    — infinite (use break)"
  , ""
  , "  break     — exit the enclosing loop"
  , "  continue  — skip to next iteration"
  , ""
  , "  Example:"
  , "    for i in 0..5 {"
  , "      if i % 2 == 0 { continue }"
  , "      println(i)"
  , "    }"
  ].join("\n")

fun doc-strings-topic() : string
  [ "  Strings"
  , ""
  , "  let s = \"hello\"                  — string literal"
  , "  \"Hello, {name}!\"                 — interpolation with {}"
  , "  \"a\" + \"b\"                        — concatenation with +"
  , ""
  , "  Escapes: \\n (newline), \\t (tab), \\\" (quote),"
  , "           \\\\{} (literal brace), \\\\\\\\ (backslash)"
  , ""
  , "  Common functions:"
  , "    str_length(s)                  — length"
  , "    trim(s)                        — strip whitespace"
  , "    to_upper(s) / to_lower(s)     — case conversion"
  , "    split(s, sep)                  — split into list"
  , "    join(xs, sep)                  — join list into string"
  , "    contains(s, sub)              — substring check"
  , "    starts_with(s, prefix)        — prefix check"
  , "    replace(s, old, new)          — replace occurrences"
  , "    parse_int(s) / parse_float(s) — parse to number (maybe)"
  ].join("\n")

fun doc-modules-topic() : string
  [ "  Modules & Imports"
  , ""
  , "  Any .hc file is a module. Use pub to export:"
  , "    pub fun hello(name) => \"hi, \" + name"
  , ""
  , "  Import:"
  , "    import \"greet\"                  — all pub items from greet.hc"
  , "    from \"greet\" import { hello }   — selective import"
  , "    pub import \"math\"               — re-export"
  , ""
  , "  Paths are relative to the importing file, no .hc extension."
  , "  Circular imports are detected and reported as errors."
  ].join("\n")

fun doc-variables-topic() : string
  [ "  Variables"
  , ""
  , "  let x = 42                      — immutable binding"
  , "  var count = 0                   — mutable variable"
  , "  count = count + 1               — reassignment (var only)"
  , ""
  , "  let is immutable — once bound, cannot change."
  , "  var is mutable but locally scoped (cannot leak)."
  , ""
  , "  The last expression in a {} block is its return value."
  , "  No 'return' keyword needed."
  , ""
  , "  Integer literals: 42, 0xFF, 0b1010, 1_000_000"
  ].join("\n")

fun doc-maybe-topic() : string
  [ "  Maybe (Optional Values)"
  , ""
  , "  Some(42)                        — a value is present"
  , "  None                            — no value"
  , ""
  , "  Pattern match:"
  , "    match result {"
  , "      Some(x) => \"got {x}\","
  , "      None    => \"nothing\""
  , "    }"
  , ""
  , "  The ? operator unwraps or returns None early:"
  , "    let x = parse_int(s)?         — None propagates up"
  , ""
  , "  Combinators:"
  , "    value |> map_maybe(f)         — transform inner value"
  , "    value |> and_then(f)          — chain maybe-returning fn"
  , "    value |> option_default(0)    — unwrap with default"
  ].join("\n")

fun doc-result-topic() : string
  [ "  Result (Success or Failure)"
  , ""
  , "  Ok(value)                       — success"
  , "  Err(\"message\")                  — failure"
  , ""
  , "  Pattern match:"
  , "    match safe_divide(10, 0) {"
  , "      Ok(n)  => println(n),"
  , "      Err(e) => println(e)"
  , "    }"
  , ""
  , "  Combinators:"
  , "    result |> map_result(f)           — transform Ok value"
  , "    result |> and_then_result(f)      — chain fallible ops"
  ].join("\n")

fun doc-testing-topic() : string
  [ "  Testing"
  , ""
  , "  test \"name\" {"
  , "    assert(condition)"
  , "    assert_eq(expected, actual)"
  , "  }"
  , ""
  , "  Run with: hica test file.hc"
  , ""
  , "  Assertions:"
  , "    assert(cond)              — fails if false"
  , "    assert_eq(a, b)           — fails if a != b"
  , "    assert_ne(a, b)           — fails if a == b"
  , "    assert_contains(xs, x)    — fails if x not in xs"
  , "    assert_empty(xs)          — fails if xs not empty"
  ].join("\n")

fun doc-operators-topic() : string
  [ "  Operators"
  , ""
  , "  Arithmetic:  + - * / %"
  , "  Comparison:  == != < > <= >="
  , "  Logical:     && ||"
  , "  Pipe:        |>  (see :doc pipe)"
  , "  Unwrap:      ?   (see :doc maybe)"
  , "  String:      +   (concatenation)"
  , ""
  , "  Bitwise (functions, not operators):"
  , "    bit_and(a, b), bit_or(a, b), bit_xor(a, b)"
  , "    bit_not(a), bit_shl(a, n), bit_shr(a, n)"
  ].join("\n")

// ---------------------------------------------------------------------------
// Function docs — name, signature, one-liner
// ---------------------------------------------------------------------------

fun doc-funs() : list<(string, string, string)>
  [ ("println", "println(value) : ()", "Print a value followed by a newline. Returns unit ().")
  , ("print", "print(value) : ()", "Print a value without a trailing newline.")
  , ("input", "input(prompt: string) : string", "Print prompt, read a line from stdin.")
  , ("length", "length(xs: list<a>) : int", "Number of elements in a list.")
  , ("head", "head(xs: list<a>) : maybe<a>", "First element, or None if empty.")
  , ("tail", "tail(xs: list<a>) : list<a>", "All elements except the first.")
  , ("map", "map(xs: list<a>, f: (a) -> b) : list<b>", "Transform each element with f.")
  , ("filter", "filter(xs: list<a>, f: (a) -> bool) : list<a>", "Keep elements where f returns true.")
  , ("foldl", "foldl(xs: list<a>, init: b, f: (b, a) -> b) : b", "Reduce a list from the left.")
  , ("reverse", "reverse(xs: list<a>) : list<a>", "Reverse a list.")
  , ("take", "take(xs: list<a>, n: int) : list<a>", "First n elements.")
  , ("drop", "drop(xs: list<a>, n: int) : list<a>", "Skip first n elements.")
  , ("zip_with", "zip_with(xs: list<a>, ys: list<b>, f: (a, b) -> c) : list<c>", "Combine two lists element-wise.")
  , ("sort", "sort(xs: list<int>) : list<int>", "Sort a list of integers.")
  , ("unique", "unique(xs: list<a>) : list<a>", "Remove consecutive duplicates.")
  , ("intersperse", "intersperse(xs: list<a>, sep: a) : list<a>", "Insert sep between elements.")
  , ("str_length", "str_length(s: string) : int", "Number of characters in a string.")
  , ("trim", "trim(s: string) : string", "Remove leading and trailing whitespace.")
  , ("to_upper", "to_upper(s: string) : string", "Convert to uppercase.")
  , ("to_lower", "to_lower(s: string) : string", "Convert to lowercase.")
  , ("split", "split(s: string, sep: string) : list<string>", "Split string by separator.")
  , ("join", "join(xs: list<string>, sep: string) : string", "Join strings with separator.")
  , ("contains", "contains(s: string, sub: string) : bool", "Check if s contains sub.")
  , ("starts_with", "starts_with(s: string, prefix: string) : bool", "Check if s starts with prefix.")
  , ("replace", "replace(s: string, old: string, new: string) : string", "Replace all occurrences.")
  , ("parse_int", "parse_int(s: string) : maybe<int>", "Parse string to int, or None.")
  , ("parse_float", "parse_float(s: string) : maybe<float>", "Parse string to float, or None.")
  , ("show", "show(value: a) : string", "Convert any value to its string representation.")
  , ("show_fixed", "show_fixed(f: float, decimals: int) : string", "Format float to N decimal places.")
  , ("abs", "abs(n: int) : int", "Absolute value.")
  , ("min", "min(a: int, b: int) : int", "Smaller of two values.")
  , ("max", "max(a: int, b: int) : int", "Larger of two values.")
  , ("pow", "pow(base: int, exp: int) : int", "Raise base to a power.")
  , ("random", "random(min: int, max: int) : int", "Random integer in [min, max] (ndet effect).")
  , ("map_maybe", "map_maybe(m: maybe<a>, f: (a) -> b) : maybe<b>", "Transform the value inside Some.")
  , ("and_then", "and_then(m: maybe<a>, f: (a) -> maybe<b>) : maybe<b>", "Chain a maybe-returning function.")
  , ("option_default", "option_default(m: maybe<a>, d: a) : a", "Unwrap with a default value.")
  , ("map_result", "map_result(r: result<a,e>, f: (a) -> b) : result<b,e>", "Transform the Ok value.")
  , ("map_get", "map_get(m: map<k,v>, key: k) : maybe<v>", "Look up a key in a map.")
  , ("map_set", "map_set(m: map<k,v>, key: k, val: v) : map<k,v>", "Add or update a key in a map.")
  , ("map_keys", "map_keys(m: map<k,v>) : list<k>", "List of all keys.")
  , ("pad_left", "pad_left(s: string, width: int, fill: string) : string", "Left-pad to width.")
  , ("pad_right", "pad_right(s: string, width: int, fill: string) : string", "Right-pad to width.")
  , ("lines", "lines(s: string) : list<string>", "Split string into lines.")
  , ("unlines", "unlines(xs: list<string>) : string", "Join lines with newline.")
  , ("words", "words(s: string) : list<string>", "Split string on whitespace.")
  , ("unwords", "unwords(xs: list<string>) : string", "Join words with space.")
  , ("repeat_str", "repeat_str(s: string, n: int) : string", "Repeat a string n times.")
  , ("index_of", "index_of(s: string, sub: string) : int", "Index of first occurrence (-1 if not found).")
  , ("read_lines", "read_lines(path: string) : list<string>", "Read file as list of lines (io effect).")
  , ("write_lines", "write_lines(path: string, xs: list<string>) : ()", "Write list of lines to file (io effect).")
  ]

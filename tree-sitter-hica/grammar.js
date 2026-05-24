/**
 * Tree-sitter grammar for Hica (.hc)
 *
 * Generate parser:
 *   npm install && npx tree-sitter generate
 *
 * Run tests:
 *   npx tree-sitter test
 *
 * Parse a file:
 *   npx tree-sitter parse examples/hello.hc
 */

module.exports = grammar({
  name: "hica",

  extras: ($) => [/\s/, $.comment, ";"],

  // Avoid ambiguity: function calls vs parenthesised expressions,
  // TypeName { } vs expression followed by a block,
  // (x, y) => … lambda vs parenthesised expression,
  // and () => expr |> f (lambda body vs pipe after lambda).
  conflicts: ($) => [
    [$.lambda_expr, $.tuple_expr],
  ],

  word: ($) => $.identifier,

  rules: {
    // ─── Top level ───────────────────────────────────────────────────────────

    source_file: ($) => repeat($._top_level_decl),

    _top_level_decl: ($) =>
      choice(
        $.import_decl,
        $.function_decl,
        $.struct_decl,
        $.type_decl,
        $.test_decl,
        $.extern_decl
      ),

    // ─── Imports ─────────────────────────────────────────────────────────────

    import_decl: ($) =>
      choice(
        // import "path"  /  pub import "path"
        seq(
          optional("pub"),
          "import",
          field("path", $.string_literal)
        ),
        // from "path" import { name1, name2 }
        seq(
          optional("pub"),
          "from",
          field("path", $.string_literal),
          "import",
          "{",
          commaSep(field("name", $.identifier)),
          "}"
        )
      ),

    // ─── Function declarations ────────────────────────────────────────────────

    function_decl: ($) =>
      seq(
        optional("pub"),
        "fun",
        field("name", $.identifier),
        field("params", $.param_list),
        optional(seq(":", field("return_type", $._type))),
        field("body", choice(
          $.block,
          seq("=>", $._expression)   // shorthand: fun f() => expr
        ))
      ),

    param_list: ($) => seq("(", commaSep($.param), ")"),

    param: ($) =>
      seq(
        field("name", $.identifier),
        optional(seq(":", field("type", $._type)))
      ),

    // ─── Struct declarations ──────────────────────────────────────────────────

    struct_decl: ($) =>
      seq(
        optional("pub"),
        "struct",
        field("name", $.type_identifier),
        "{",
        commaSep($.struct_field_decl),
        "}"
      ),

    struct_field_decl: ($) =>
      seq(
        optional("pub"),
        field("name", $.identifier),
        ":",
        field("type", $._type)
      ),

    // ─── Type (enum) declarations ─────────────────────────────────────────────

    type_decl: ($) =>
      seq(
        optional("pub"),
        "type",
        field("name", $.type_identifier),
        "{",
        commaSep($.type_variant),
        "}"
      ),

    type_variant: ($) =>
      seq(
        field("name", $.type_identifier),
        optional(seq("(", commaSep($.variant_field), ")"))
      ),

    // Circle(radius: float)  or  Circle(float)  — labeled or bare
    variant_field: ($) =>
      choice(
        seq(field("name", $.identifier), ":", field("type", $._type)),
        $._type
      ),

    // ─── Test declarations ────────────────────────────────────────────────────

    test_decl: ($) =>
      seq("test", field("name", $.string_literal), field("body", $.block)),

    // ─── Extern declarations ──────────────────────────────────────────────────

    extern_decl: ($) =>
      seq(
        optional("pub"),
        "extern",
        "fun",
        field("name", $.identifier),
        field("params", $.param_list),
        ":",
        field("return_type", $._type)
      ),

    // ─── Types ───────────────────────────────────────────────────────────────

    _type: ($) =>
      choice(
        $.primitive_type,
        $.generic_type,
        $.tuple_type,
        $.function_type,
        $.type_identifier
      ),

    primitive_type: ($) =>
      choice("int", "float", "bool", "string", "char", "maybe", "list", "result"),

    generic_type: ($) =>
      prec(1, seq(
        // both `Maybe<T>` (PascalCase) and `maybe<T>`, `list<T>` (lowercase)
        field("base", choice($.type_identifier, $.primitive_type, $.identifier)),
        "<",
        commaSep($._type),
        ">"
      )),

    tuple_type: ($) => seq("(", commaSep($._type), ")"),

    function_type: ($) =>
      seq("(", commaSep($._type), ")", "->", $._type),

    // ─── Block ───────────────────────────────────────────────────────────────

    block: ($) =>
      seq("{", repeat($._statement_or_expr), "}"),

    _statement_or_expr: ($) =>
      choice($.let_stmt, $.var_stmt, $.assign_stmt, $.return_stmt, $.break_stmt, $.continue_stmt, $._expression),

    // ─── Statements ──────────────────────────────────────────────────────────

    let_stmt: ($) =>
      seq(
        "let",
        field("name", choice($.identifier, $.tuple_pattern)),
        optional(seq(":", field("type", $._type))),
        "=",
        field("value", $._expression)
      ),

    var_stmt: ($) =>
      seq(
        "var",
        field("name", $.identifier),
        optional(seq(":", field("type", $._type))),
        "=",
        field("value", $._expression)
      ),

    assign_stmt: ($) =>
      seq(
        field("target", $.identifier),
        "=",
        field("value", $._expression)
      ),

    return_stmt: ($) => prec.right(seq("return", optional($._expression))),

    break_stmt: (_) => "break",

    continue_stmt: (_) => "continue",

    // ─── Expressions (Pratt-style precedence) ─────────────────────────────────

    _expression: ($) =>
      choice(
        $.pipe_expr,
        $.binary_expr,
        $.unary_expr,
        $.try_expr,
        $.call_expr,
        $.field_expr,
        $.index_expr,
        $.slice_expr,
        $.if_expr,
        $.match_expr,
        $.for_expr,
        $.while_expr,
        $.loop_expr,
        $.lambda_expr,
        $.block,
        $.struct_literal,
        $.struct_update,
        $.list_literal,
        $.map_literal,
        $.tuple_expr,
        $.paren_expr,
        $.string_literal,
        $.char_literal,
        $.float_literal,
        $.integer_literal,
        $.boolean_literal,
        $.none_literal,
        $.type_identifier,
        $.identifier
      ),

    pipe_expr: ($) =>
      prec.left(1, seq(field("left", $._expression), "|>", field("right", $._expression))),

    binary_expr: ($) =>
      choice(
        prec.left(1, seq($._expression, choice("..", "..="), $._expression)),   // range
        prec.left(1, seq($._expression, "in", $._expression)),                  // membership
        prec.left(2, seq($._expression, "||", $._expression)),
        prec.left(3, seq($._expression, "&&", $._expression)),
        prec.left(4, seq($._expression, choice("==", "!=", "<", ">", "<=", ">="), $._expression)),
        prec.left(5, seq($._expression, choice("+", "-"), $._expression)),
        prec.left(6, seq($._expression, choice("*", "/", "%"), $._expression))
      ),

    unary_expr: ($) =>
      prec(7, seq(choice("!", "-"), $._expression)),

    // foo?  — early-return on None / Err
    try_expr: ($) => prec(10, seq($._expression, "?")),

    call_expr: ($) =>
      prec(8,
        seq(
          field("function", $._expression),
          "(",
          commaSep($._expression),
          ")"
        )
      ),

    // obj.field  or  tuple.0  (integer index for tuples)
    field_expr: ($) =>
      prec(9, seq(
        field("object", $._expression),
        ".",
        field("field", choice($.identifier, $.integer_literal))
      )),

    index_expr: ($) =>
      prec(9, seq(field("object", $._expression), "[", field("index", $._expression), "]")),

    // a[1:3]  a[:2]  a[3:]
    slice_expr: ($) =>
      prec(9, seq(
        field("object", $._expression),
        "[",
        field("from", optional($._expression)),
        ":",
        field("to", optional($._expression)),
        "]"
      )),

    if_expr: ($) =>
      seq(
        "if",
        field("condition", $._expression),
        field("then", $.block),
        optional(seq("else", field("else", choice($.block, $.if_expr))))
      ),

    match_expr: ($) =>
      seq("match", field("value", $._expression), "{", repeat($.match_arm), "}"),

    // Arms are separated by an optional trailing comma.
    // Using repeat(match_arm) instead of commaSep avoids `,` ambiguity
    // when the arm body is a tuple expression (v, "x").
    match_arm: ($) =>
      seq(field("pattern", $._pattern), "=>", field("body", $._expression), optional(",")),

    // ─── Patterns ────────────────────────────────────────────────────────────

    _pattern: ($) =>
      choice(
        $.or_pattern,
        $._single_pattern
      ),

    // "Saturday" | "Sunday"
    or_pattern: ($) =>
      prec.left(1, seq($._single_pattern, repeat1(seq("|", $._single_pattern)))),

    _single_pattern: ($) =>
      choice(
        $.wildcard_pattern,
        $.range_pattern,
        $.struct_pattern,
        $.constructor_pattern,
        $.list_pattern,
        $.tuple_pattern,
        $.literal_pattern,
        $.identifier,
        $.type_identifier
      ),

    // Point { x: 0, y }  in match arms
    struct_pattern: ($) =>
      seq(
        field("type", $.type_identifier),
        "{",
        commaSep($.struct_field_pattern),
        "}"
      ),

    struct_field_pattern: ($) =>
      choice(
        seq(field("name", $.identifier), ":", field("pattern", $._single_pattern)),
        field("name", $.identifier)  // shorthand: binds as variable with same name
      ),

    // 0..=59  or  0..59
    range_pattern: ($) =>
      seq($._range_bound, choice("..", "..="), $._range_bound),

    _range_bound: ($) => choice($.integer_literal, $.float_literal),

    wildcard_pattern: (_) => "_",

    rest_pattern: ($) => seq("..", optional($.identifier)),

    constructor_pattern: ($) =>
      seq(field("name", $.type_identifier), "(", commaSep($._pattern), ")"),

    list_pattern: ($) =>
      seq("[", commaSep($._list_pattern_element), "]"),

    _list_pattern_element: ($) => choice($._pattern, $.rest_pattern),

    tuple_pattern: ($) => seq("(", commaSep($._pattern), ")"),

    literal_pattern: ($) =>
      choice($.string_literal, $.integer_literal, $.float_literal, $.boolean_literal, $.none_literal),

    // ─── Iteration ───────────────────────────────────────────────────────────

    for_expr: ($) =>
      seq(
        "for",
        field("variable", $.identifier),
        "in",
        field("iterable", $._expression),
        field("body", $.block)
      ),

    while_expr: ($) =>
      seq("while", field("condition", $._expression), field("body", $.block)),

    // loop { ... break ... }  — infinite loop
    loop_expr: ($) =>
      seq("loop", field("body", $.block)),

    // ─── Lambda ──────────────────────────────────────────────────────────────

    // () => body  (params accept expressions at grammar level; semantic checker validates identifiers)
    lambda_expr: ($) =>
      prec.right(1,
        seq(
          "(",
          commaSep(field("param", $._expression)),
          ")",
          "=>",
          field("body", choice($.block, $._expression))
        )
      ),

    // ─── Struct / map literals ────────────────────────────────────────────────

    struct_literal: ($) =>
      prec(1, seq(field("type", $.type_identifier), "{", commaSep($.struct_field_init), "}")),


    // `TypeName { ...base, field: val }` struct update with spread
    struct_update: ($) =>
      prec(1, seq(
        field("type", $.type_identifier),
        "{",
        "...",
        field("base", $.identifier),
        optional(seq(",", commaSep($.struct_field_init))),
        "}"
      )),

    struct_field_init: ($) =>
      seq(field("name", $.identifier), ":", field("value", $._expression)),

    list_literal: ($) => seq("[", commaSep($._expression), "]"),

    // Empty map must use {:} — {} is always a block
    map_literal: ($) =>
      choice(
        seq("{", ":", "}"),
        seq("{", commaSep1($.map_entry), "}")
      ),

    map_entry: ($) =>
      seq(field("key", $.string_literal), ":", field("value", $._expression)),

    // (a, b)  — requires at least one comma to distinguish from (expr)
    tuple_expr: ($) =>
      seq("(", $._expression, ",", commaSep($._expression), ")"),

    // (expr)  — parenthesized grouping; disambiguated from lambda by absence of =>
    paren_expr: ($) => seq("(", $._expression, ")"),

    // ─── Literals ─────────────────────────────────────────────────────────────

    string_literal: ($) =>
      seq(
        '"',
        repeat(
          choice(
            $.escape_sequence,
            $.string_interpolation,
            token.immediate(prec(1, /[^"\\{]+/))
          )
        ),
        '"'
      ),

    escape_sequence: (_) => /\\[nrtf0\\"'{}]/,

    string_interpolation: ($) =>
      seq(
        "{",
        $._expression,
        "}"
      ),

    char_literal: (_) => /'([^'\\]|\\[nrtf0\\'"])'/,

    integer_literal: (_) =>
      choice(
        /0[bB][01_]+/,
        /0[xX][0-9a-fA-F_]+/,
        /[0-9][0-9_]*/
      ),

    float_literal: (_) => /[0-9][0-9_]*\.[0-9][0-9_]*/,

    boolean_literal: (_) => choice("true", "false"),

    none_literal: (_) => "None",

    // ─── Identifiers ─────────────────────────────────────────────────────────

    // lowercase_snake_case
    identifier: (_) => /[a-z_][a-zA-Z0-9_]*/,

    // PascalCase — types and constructors
    type_identifier: (_) => /[A-Z][a-zA-Z0-9_]*/,

    // ─── Comments ─────────────────────────────────────────────────────────────

    comment: (_) => /\/\/.*/,
  },
});

/**
 * Match zero or more comma-separated occurrences of `rule`,
 * with an optional trailing comma.
 */
function commaSep(rule) {
  return optional(seq(rule, repeat(seq(",", rule)), optional(",")));
}

/**
 * Match one or more comma-separated occurrences of `rule`,
 * with an optional trailing comma.
 */
function commaSep1(rule) {
  return seq(rule, repeat(seq(",", rule)), optional(","));
}

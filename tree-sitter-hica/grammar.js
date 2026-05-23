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

  extras: ($) => [/\s/, $.comment],

  // Avoid ambiguity: function calls vs parenthesised expressions
  conflicts: ($) => [[$.call_expr, $._expression]],

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
      seq(
        optional("pub"),
        "import",
        field("path", $.string_literal),
        optional(
          seq("(", commaSep(field("name", $.identifier)), ")")
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
        field("body", $.block)
      ),

    param_list: ($) => seq("(", commaSep($.param), ")"),

    param: ($) =>
      seq(field("name", $.identifier), ":", field("type", $._type)),

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
        optional(seq("(", commaSep($._type), ")"))
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
      choice("int", "float", "bool", "string", "char"),

    generic_type: ($) =>
      seq(
        field("base", $.type_identifier),
        "<",
        commaSep($._type),
        ">"
      ),

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
        field("name", $.identifier),
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

    return_stmt: ($) => seq("return", optional($._expression)),

    break_stmt: (_) => "break",

    continue_stmt: (_) => "continue",

    // ─── Expressions (Pratt-style precedence) ─────────────────────────────────

    _expression: ($) =>
      choice(
        $.pipe_expr,
        $.binary_expr,
        $.unary_expr,
        $.call_expr,
        $.field_expr,
        $.index_expr,
        $.if_expr,
        $.match_expr,
        $.for_expr,
        $.while_expr,
        $.lambda_expr,
        $.block,
        $.struct_literal,
        $.struct_update,
        $.list_literal,
        $.map_literal,
        $.tuple_expr,
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
        prec.left(2, seq($._expression, choice("||"), $._expression)),
        prec.left(3, seq($._expression, "&&", $._expression)),
        prec.left(4, seq($._expression, choice("==", "!=", "<", ">", "<=", ">="), $._expression)),
        prec.left(5, seq($._expression, choice("+", "-"), $._expression)),
        prec.left(6, seq($._expression, choice("*", "/", "%"), $._expression))
      ),

    unary_expr: ($) =>
      prec(7, seq(choice("!", "-"), $._expression)),

    call_expr: ($) =>
      prec(8,
        seq(
          field("function", $._expression),
          "(",
          commaSep($._expression),
          ")"
        )
      ),

    field_expr: ($) =>
      prec(9, seq(field("object", $._expression), ".", field("field", $.identifier))),

    index_expr: ($) =>
      prec(9, seq(field("object", $._expression), "[", field("index", $._expression), "]")),

    if_expr: ($) =>
      seq(
        "if",
        field("condition", $._expression),
        field("then", $.block),
        optional(seq("else", field("else", choice($.block, $.if_expr))))
      ),

    match_expr: ($) =>
      seq("match", field("value", $._expression), "{", commaSep($.match_arm), "}"),

    match_arm: ($) =>
      seq(field("pattern", $._pattern), "=>", field("body", $._expression)),

    // ─── Patterns ────────────────────────────────────────────────────────────

    _pattern: ($) =>
      choice(
        $.wildcard_pattern,
        $.rest_pattern,
        $.constructor_pattern,
        $.list_pattern,
        $.tuple_pattern,
        $.literal_pattern,
        $.identifier,
        $.type_identifier
      ),

    wildcard_pattern: (_) => "_",

    rest_pattern: ($) => seq("..", $.identifier),

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

    // ─── Lambda ──────────────────────────────────────────────────────────────

    lambda_expr: ($) =>
      seq(
        "(",
        commaSep(field("param", $.identifier)),
        ")",
        "=>",
        field("body", choice($.block, $._expression))
      ),

    // ─── Struct / map literals ────────────────────────────────────────────────

    struct_literal: ($) =>
      seq(field("type", $.type_identifier), "{", commaSep($.struct_field_init), "}"),

    struct_update: ($) =>
      seq(
        "{",
        "...",
        field("base", $.identifier),
        optional(seq(",", commaSep($.struct_field_init))),
        "}"
      ),

    struct_field_init: ($) =>
      seq(field("name", $.identifier), ":", field("value", $._expression)),

    list_literal: ($) => seq("[", commaSep($._expression), "]"),

    map_literal: ($) =>
      choice(
        seq("{", ":", "}"),
        seq("{", commaSep($.map_entry), "}")
      ),

    map_entry: ($) =>
      seq(field("key", $.string_literal), ":", field("value", $._expression)),

    tuple_expr: ($) =>
      seq("(", $._expression, ",", commaSep($._expression), ")"),

    // ─── Literals ─────────────────────────────────────────────────────────────

    string_literal: ($) =>
      seq(
        '"',
        repeat(
          choice(
            $.escape_sequence,
            $.string_interpolation,
            /[^"\\{]+/
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

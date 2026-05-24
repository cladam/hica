; Tree-sitter highlight queries for Hica
; Used by Neovim (nvim-treesitter), Helix, Zed, etc.
;
; Capture names follow the nvim-treesitter standard:
;   https://github.com/nvim-treesitter/nvim-treesitter/blob/master/CONTRIBUTING.md

; ─── Comments ────────────────────────────────────────────────────────────────

(comment) @comment @spell

; ─── Keywords ────────────────────────────────────────────────────────────────

[
  "if" "else" "match"
  "for" "in" "while" "loop" "repeat"
  "return"
] @keyword.control

(break_stmt)    @keyword.control
(continue_stmt) @keyword.control

[
  "fun" "let" "var" "struct" "type" "extern"
] @keyword

(import_decl "import" @keyword.import)
(import_decl "from"   @keyword.import)
(import_decl "pub"    @keyword.modifier)

(function_decl "pub"  @keyword.modifier)
(struct_decl   "pub"  @keyword.modifier)
(type_decl     "pub"  @keyword.modifier)
(extern_decl   "pub"  @keyword.modifier)

(test_decl "test" @keyword.test)

; ─── Types ───────────────────────────────────────────────────────────────────

(primitive_type) @type.builtin

(type_identifier) @type

(function_decl   return_type: (_) @type)
(extern_decl     return_type: (_) @type)
(param           type: (_) @type)
(let_stmt        type: (_) @type)
(var_stmt        type: (_) @type)

; ─── Declarations ─────────────────────────────────────────────────────────────

(function_decl name: (identifier)      @function)
(extern_decl   name: (identifier)      @function)
(struct_decl   name: (type_identifier) @type.definition)
(type_decl     name: (type_identifier) @type.definition)
(type_variant  name: (type_identifier) @constructor)

(test_decl name: (string_literal) @string.special.test)

; ─── Calls ────────────────────────────────────────────────────────────────────

(call_expr
  function: (identifier)  @function.call)

(call_expr
  function: (field_expr
    field: (identifier)   @function.method.call))

; ─── Variables ────────────────────────────────────────────────────────────────

(let_stmt  name: (identifier) @variable)
(var_stmt  name: (identifier) @variable)
(param     name: (identifier) @variable.parameter)
(for_expr  variable: (identifier) @variable)

(lambda_expr
  param: (identifier) @variable.parameter)

(assign_stmt
  target: (identifier) @variable)

(identifier) @variable

; ─── Properties ──────────────────────────────────────────────────────────────

(field_expr        field: (identifier)      @variable.member)
(struct_field_decl name:  (identifier)      @variable.member)
(struct_field_init name:  (identifier)      @variable.member)
(map_entry         key:   (string_literal)  @variable.member)

; ─── Built-in constructors ───────────────────────────────────────────────────

((type_identifier) @constructor.builtin
  (#any-of? @constructor.builtin "Some" "Ok" "Err" "None"))

((boolean_literal) @boolean)
(none_literal)     @constant.builtin

; ─── Literals ────────────────────────────────────────────────────────────────

(string_literal)    @string
(escape_sequence)   @string.escape
(char_literal)      @character
(integer_literal)   @number
(float_literal)     @number.float

(string_interpolation
  "{" @punctuation.special
  "}" @punctuation.special)

; ─── Operators ────────────────────────────────────────────────────────────────

"|>"  @operator           ; pipe
"=>"  @operator           ; match arm / lambda arrow
"->"  @operator           ; type arrow
"..." @operator           ; spread
"..=" @operator           ; inclusive range
".."  @operator           ; range / rest

["==" "!=" "<=" ">=" "<" ">"] @operator
["&&" "||" "!"]               @operator
["+"  "-"  "*"  "/"  "%"]     @operator
"="                           @operator
"?"                           @operator

; ─── Punctuation ─────────────────────────────────────────────────────────────

["(" ")" "[" "]" "{" "}"] @punctuation.bracket
["," ";" ":"]              @punctuation.delimiter
"."                        @punctuation.delimiter

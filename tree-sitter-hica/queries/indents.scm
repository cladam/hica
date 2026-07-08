; Tree-sitter indent queries for hica
; Tells the editor when to indent/dedent.

; Increase indent inside braces and brackets
[
  (block)
  (struct_literal)
  (map_literal)
  (list_literal)
  (param_list)
] @indent

; Decrease indent for closing delimiter
[
  "}"
  "]"
  ")"
] @indent.end

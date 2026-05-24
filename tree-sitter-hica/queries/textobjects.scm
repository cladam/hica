; Textobjects — used by nvim-treesitter-textobjects
; Lets you do  vaf  (select a function),  dac  (delete a class), etc.

; @function.outer / @function.inner
(function_decl) @function.outer
(function_decl body: (block) @function.inner)

; @class.outer / @class.inner  (structs and types)
(struct_decl) @class.outer
(type_decl)   @class.outer

; @parameter.outer / @parameter.inner
(param) @parameter.outer
(param name: (_) @parameter.inner)

; @conditional.outer / @conditional.inner
(if_expr) @conditional.outer
(if_expr then: (block) @conditional.inner)

; @loop.outer / @loop.inner
(for_expr)    @loop.outer
(while_expr)  @loop.outer
(loop_expr)   @loop.outer
(repeat_expr) @loop.outer
(for_expr    body: (block) @loop.inner)
(while_expr  body: (block) @loop.inner)
(loop_expr   body: (block) @loop.inner)
(repeat_expr body: (block) @loop.inner)

; @call.outer / @call.inner
(call_expr) @call.outer
(call_expr (identifier) @call.inner)

; @block.outer / @block.inner
(block) @block.outer
(block) @block.inner

; @comment.outer
(comment) @comment.outer

" Vim syntax file for hica (.hc)
" Language:    hica
" Maintainer:  cladam
" URL:         https://github.com/cladam/hica

if exists("b:current_syntax")
  finish
endif

" ─── Keywords ────────────────────────────────────────────────────────────────

syntax keyword hicaControl    if else match for in while loop repeat break continue return
syntax keyword hicaDecl       fun let var struct type extern
syntax keyword hicaImport     import from
syntax keyword hicaModifier   pub
syntax keyword hicaTest       test

" ─── Literals ─────────────────────────────────────────────────────────────────

syntax keyword hicaBoolean    true false
syntax keyword hicaNone       None
syntax keyword hicaBuiltinCon Some Ok Err

" ─── Primitive types ──────────────────────────────────────────────────────────

syntax keyword hicaType       int float bool string char list maybe result

" ─── User-defined PascalCase types and constructors ──────────────────────────

syntax match   hicaUserType   "\<[A-Z][a-zA-Z0-9_]*\>"

" ─── Function declarations ────────────────────────────────────────────────────
" Matches:  fun my_function(
syntax match   hicaFuncName   "\(\<fun\s\+\)\@<=[a-z_][a-zA-Z0-9_]*" contained
syntax match   hicaFuncDecl   "\<fun\s\+[a-z_][a-zA-Z0-9_]*" contains=hicaDecl,hicaFuncName

" ─── Test declaration name ────────────────────────────────────────────────────
" Matches:  test "my test name"
syntax match   hicaTestName   "\(\<test\s\+\)\@<=\"[^\"]*\"" contained
syntax match   hicaTestDecl   "\<test\s\+\"[^\"]*\"" contains=hicaTest,hicaTestName

" ─── Function calls ───────────────────────────────────────────────────────────
" Matches:  foo(  — but not fun foo(
syntax match   hicaFuncCall   "\<[a-z_][a-zA-Z0-9_]*\ze\s*("

" ─── Comments ────────────────────────────────────────────────────────────────

syntax match   hicaComment    "//.*$"

" ─── Strings ─────────────────────────────────────────────────────────────────

syntax region  hicaString     start=+"+ end=+"+ skip=+\\"+ contains=hicaEscape,hicaInterp
syntax match   hicaEscape     "\\[nrtf0\\\"'{}]" contained
syntax region  hicaInterp     start="{" end="}" contained contains=hicaInterpContent
syntax cluster hicaInterpContent contains=hicaFuncCall,hicaUserType,hicaBoolean,hicaNone,hicaNumber,hicaFloat,@hicaOps

" ─── Characters ──────────────────────────────────────────────────────────────

syntax match   hicaChar       "'[^'\\]'\|'\\[nrtf0\\\"']'"

" ─── Numbers ─────────────────────────────────────────────────────────────────

syntax match   hicaNumber     "\<0[bB][01_]*\>"
syntax match   hicaNumber     "\<0[xX][0-9a-fA-F_]*\>"
syntax match   hicaNumber     "\<[0-9][0-9_]*\>"
syntax match   hicaFloat      "\<[0-9][0-9_]*\.[0-9][0-9_]*\>"

" ─── Operators ───────────────────────────────────────────────────────────────

syntax match   hicaOpPipe     "|>"
syntax match   hicaOpArrow    "=>"
syntax match   hicaOpThinArr  "->"
syntax match   hicaOpSpread   "\.\.\."
syntax match   hicaOpRange    "\.\.\="
syntax match   hicaOpRange    "\.\."
syntax match   hicaOpTry      "?"
syntax match   hicaOpCmp      "==\|!=\|<=\|>="
syntax match   hicaOpLogic    "&&\|\|\|"
syntax match   hicaOpUnary    "\<!\ze[^=]"
syntax match   hicaOpArith    "[+\-*/%]"
syntax match   hicaOpRel      "[<>]"
syntax match   hicaOpAssign   "="

syntax cluster hicaOps contains=hicaOpPipe,hicaOpArrow,hicaOpThinArr,hicaOpSpread,hicaOpRange,hicaOpTry,hicaOpCmp,hicaOpLogic,hicaOpUnary,hicaOpArith,hicaOpRel,hicaOpAssign

" ─── Highlight Links ─────────────────────────────────────────────────────────

highlight default link hicaControl    Keyword
highlight default link hicaDecl       Keyword
highlight default link hicaImport     Include
highlight default link hicaModifier   StorageClass
highlight default link hicaTest       Keyword

highlight default link hicaBoolean    Boolean
highlight default link hicaNone       Constant
highlight default link hicaBuiltinCon Structure

highlight default link hicaType       Type
highlight default link hicaUserType   Type

highlight default link hicaFuncName   Function
highlight default link hicaFuncCall   Function
highlight default link hicaTestName   String

highlight default link hicaComment    Comment

highlight default link hicaString     String
highlight default link hicaEscape     SpecialChar
highlight default link hicaInterp     Special

highlight default link hicaChar       Character

highlight default link hicaNumber     Number
highlight default link hicaFloat      Float

highlight default link hicaOpPipe     Operator
highlight default link hicaOpArrow    Operator
highlight default link hicaOpThinArr  Operator
highlight default link hicaOpSpread   Operator
highlight default link hicaOpRange    Operator
highlight default link hicaOpTry      Operator
highlight default link hicaOpCmp      Operator
highlight default link hicaOpLogic    Operator
highlight default link hicaOpUnary    Operator
highlight default link hicaOpArith    Operator
highlight default link hicaOpRel      Operator
highlight default link hicaOpAssign   Operator

let b:current_syntax = "hica"

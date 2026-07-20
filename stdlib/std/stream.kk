// stream.kk — Lazy stream processing for hica
//
// Built-in stdlib module, auto-imported when stream<a> operations are used.
// Users import via: import "std/stream"  (not needed when using built-in stream ops)
//
// A Stream<a> is a thunk-linked list: each step either ends (Done) or
// yields one value plus a thunk that produces the rest.
// Transformations (filter, map, take) wrap thunks — no list is allocated until
// collect/fold/foreach forces evaluation.
//
// This source file is part of the hica open source project
// Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
//
// See https://github.com/cladam/hica/blob/main/LICENSE for license information
module hc-stream

// ---------------------------------------------------------------------------
// Stream type
// ---------------------------------------------------------------------------

pub type stream-t<a>
  Done
  Yield( head : a, tail : () -> div stream-t<a> )

// ---------------------------------------------------------------------------
// Entry points
// ---------------------------------------------------------------------------

// Identity function on streams.
pub fun as-stream( s : stream-t<a> ) : div stream-t<a>
  s

// Create a stream from a list.
pub fun stream( xs : list<a> ) : div stream-t<a>
  match xs
    Nil        -> Done
    Cons(h, t) -> Yield(h, fn() { stream(t) })

// ---------------------------------------------------------------------------
// Lazy transformations (no evaluation until a terminator is called)
// ---------------------------------------------------------------------------

// Keep only elements where pred returns true.
pub fun filter( s : stream-t<a>, pred : (a) -> bool ) : div stream-t<a>
  match s
    Done           -> Done
    Yield(x, next) ->
      if pred(x) then Yield(x, fn() { filter(next(), pred) })
      else filter(next(), pred)

// Transform each element with f.
pub fun map( s : stream-t<a>, f : (a) -> b ) : div stream-t<b>
  match s
    Done           -> Done
    Yield(x, next) -> Yield(f(x), fn() { map(next(), f) })

// Expand each element into a sub-stream and concatenate.
pub fun flat-map( s : stream-t<a>, f : (a) -> div stream-t<b> ) : div stream-t<b>
  match s
    Done           -> Done
    Yield(x, next) -> stream-append(f(x), fn() { flat-map(next(), f) })

fun stream-append( s1 : stream-t<a>, rest : () -> div stream-t<a> ) : div stream-t<a>
  match s1
    Done           -> rest()
    Yield(x, next) -> Yield(x, fn() { stream-append(next(), rest) })

// Take the first n elements; stops the generator early.
pub fun take( s : stream-t<a>, n : int ) : div stream-t<a>
  if n <= 0 then Done
  else match s
    Done           -> Done
    Yield(x, next) -> Yield(x, fn() { take(next(), n - 1) })

// Take elements while pred holds; stops on first failure.
pub fun take-while( s : stream-t<a>, pred : (a) -> bool ) : div stream-t<a>
  match s
    Done           -> Done
    Yield(x, next) ->
      if pred(x) then Yield(x, fn() { take-while(next(), pred) })
      else Done

// Skip elements while pred holds; return the rest.
pub fun drop-while( s : stream-t<a>, pred : (a) -> bool ) : div stream-t<a>
  match s
    Done           -> Done
    Yield(x, next) ->
      if pred(x) then drop-while(next(), pred)
      else s

// Pair elements from two streams; stops when either ends.
pub fun zip( s1 : stream-t<a>, s2 : stream-t<b> ) : div stream-t<(a,b)>
  match s1
    Done           -> Done
    Yield(x, next1) ->
      match s2
        Done           -> Done
        Yield(y, next2) -> Yield((x, y), fn() { zip(next1(), next2()) })

// Pair each element with its 0-based index.
pub fun enumerate( s : stream-t<a> ) : div stream-t<(int,a)>
  enumerate-from(s, 0)

fun enumerate-from( s : stream-t<a>, n : int ) : div stream-t<(int,a)>
  match s
    Done           -> Done
    Yield(x, next) -> Yield((n, x), fn() { enumerate-from(next(), n + 1) })

// ---------------------------------------------------------------------------
// Terminators (these force evaluation of the stream)
// ---------------------------------------------------------------------------

// Materialise the stream into a list.
pub fun collect( s : stream-t<a> ) : div list<a>
  match s
    Done           -> Nil
    Yield(x, next) -> Cons(x, collect(next()))

// Reduce the stream to a single value without building an intermediate list.
pub fun fold( s : stream-t<a>, init : b, f : (b, a) -> b ) : div b
  match s
    Done           -> init
    Yield(x, next) -> fold(next(), f(init, x), f)

// Call f on each element for its side effects. Effect e is inferred from f.
pub fun foreach( s : stream-t<a>, f : (a) -> <div|e> () ) : <div|e> ()
  match s
    Done           -> ()
    Yield(x, next) ->
      f(x)
      foreach(next(), f)

// xform.hc — Pipeline transducers for hica
//
// Build reusable stream transformations without allocating intermediate collections,
// and apply them to any compatible list/stream source.
//
// This is additive on top of std/stream.

import "std/stream"
import "std/list"

// Start of a chain (1-argument constructors)
pub fun xf_filter(pred) =>
  (s) => as_stream(s) |> filter(pred)

pub fun xf_map_start(f) =>
  (s) => as_stream(s) |> map(f)

pub fun xf_take_start(n) =>
  (s) => as_stream(s) |> take(n)

pub fun xf_take_while_start(pred) =>
  (s) => as_stream(s) |> take_while(pred)

pub fun xf_drop_while_start(pred) =>
  (s) => as_stream(s) |> drop_while(pred)

pub fun xf_flat_map_start(f) =>
  (s) => as_stream(s) |> flat_map(f)

// Middle of a chain (2-argument composition steps)
pub fun xf_map(xform, f) =>
  (s) => as_stream(s) |> xform |> as_stream |> map(f)

pub fun xf_filter_with(xform, pred) =>
  (s) => as_stream(s) |> xform |> as_stream |> filter(pred)

pub fun xf_take(xform, n) =>
  (s) => as_stream(s) |> xform |> as_stream |> take(n)

pub fun xf_take_while(xform, pred) =>
  (s) => as_stream(s) |> xform |> as_stream |> take_while(pred)

pub fun xf_drop_while(xform, pred) =>
  (s) => as_stream(s) |> xform |> as_stream |> drop_while(pred)

pub fun xf_flat_map(xform, f) =>
  (s) => as_stream(s) |> xform |> as_stream |> flat_map(f)

// Base identity/initialization transducer if someone wants to start with a standard 2-argument operation
pub fun xf_start() =>
  (s) => as_stream(s)

// Apply the transducer to a compatible source list and collect the results.
pub fun transduce(xs, xform) =>
  stream(xs) |> xform |> collect()

// hica – actor stdlib module
//
// Phase 1: sequential actor pattern (state machine model).
// An actor is modelled as: state + receive function + mailbox.
// Import with: import "std/actor"
//
// This source file is part of the hica open source project
// Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
//
// See https://github.com/cladam/hica/blob/main/LICENSE for license information

// Process a list of messages through a receive function, returning final state.
// This is the actor "run loop": fold messages through state transitions.
//
// Usage:
//   let final_state = process_messages(initial_state, messages, receive_fn)
//
pub fun process_messages(state, messages, receive) =>
  fold(messages, state, receive)

// Send a fire-and-forget message to an actor, discarding the returned state (returns unit / ()).
// This is useful for messages that trigger side-effects or modify state without leaking it.
//
// Usage:
//   send(state, msg, receive_fn)
//
pub fun send(state, msg, receive) =>
  (receive(state, msg), ()).1

// Send a request message to an actor and return a projected value/reply.
//
// Usage:
//   let val = ask(state, msg, receive_fn, (next_state) => next_state.field)
//
pub fun ask(state, msg, receive, project) =>
  project(receive(state, msg))

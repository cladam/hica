// hica – actor prelude
//
// A minimal actor pattern library for educational purposes.
// Actors are modeled as state machines: state + receive function.
//
// This is Phase 1 (sequential, no concurrency). The pattern provides:
//   - Message types as enums (compile-time exhaustive match)
//   - Receive as a pure function: (state, msg) -> state
//   - process_messages: fold over a mailbox
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

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

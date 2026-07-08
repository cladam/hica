// Mental process simulator — Weekend Edition
//
// Original: Koka with algebraic effect handlers (brain + weekend).
// hica version: two actors as state machines with message types.
//
// Two actors cooperate:
//   - Brain: manages the thought stack, can flush its buffer
//   - Weekend: monitors the environment, can trigger step-away

import "std/actor"

// --- Brain actor ---

type BrainMsg {
  Think,
  FlushBuffer
}

struct BrainState {
  thoughts: list<string>
}

fun brain_receive(state: BrainState, msg: BrainMsg) => match msg {
  Think => {
    println("Processing: {current_thought(state.thoughts)}")
    state
  },
  FlushBuffer => {
    println("[Mental]: Buffer cleared. State serialized to paper.")
    BrainState { thoughts: [] }
  }
}

fun current_thought(thoughts: list<string>) : string => match thoughts {
  [h, ..rest] => h,
  []          => "nothing"
}

// --- Weekend actor ---

type WeekendMsg {
  StepAway
}

struct WeekendState {
  sunny: bool
}

fun weekend_receive(state: WeekendState, msg: WeekendMsg) => match msg {
  StepAway => {
    println("[Environment]: Initiating physical disconnect. System cooling down...")
    if state.sunny {
      println("[Weekend]: It's sunny outside! Go touch some grass.")
    }
    state
  }
}

// --- Orchestration ---

fun handle_overflow(brain: BrainState, weekend: WeekendState) {
  println("Stack Overflow: Too many spinning pieces ({length(brain.thoughts)})")
  println("[Mental]: Buffer cleared. State serialized to paper.")
  println("[Environment]: Initiating physical disconnect. System cooling down...")
  if weekend.sunny {
    println("[Weekend]: It's sunny outside! Go touch some grass.")
  }
}

fun mental_process(brain: BrainState, weekend: WeekendState) {
  if length(brain.thoughts) >= 5 {
    handle_overflow(brain, weekend)
  } else {
    process_messages(brain, [Think], brain_receive)
    mental_process(brain, weekend)
  }
}

fun main() {
  let brain = BrainState { thoughts: ["Re-org", "Budget", "Relationships", "Tinnitus", "Politics"] }
  let weekend = WeekendState { sunny: true }
  mental_process(brain, weekend)
}

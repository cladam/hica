// Hica — typed workflow state machine
//
// A deploy → health-check → rollback workflow modelled as an explicit
// state machine. States are enum variants; each step is a function that
// takes the current state and returns the next state plus a log message.
//
// This is a prototype of the "typed workflow choreography" concept:
// the type system enforces that only valid transitions can be expressed.

// ---------------------------------------------------------------------------
// State definition — all reachable states in the workflow
// ---------------------------------------------------------------------------

type DeployState {
  Idle,
  Deploying,
  Healthy,
  Degraded,
  RolledBack
}

// ---------------------------------------------------------------------------
// Transition result — every step returns its next state and a log line
// ---------------------------------------------------------------------------

struct Transition {
  next: DeployState,
  log: string
}

// ---------------------------------------------------------------------------
// Steps — typed state transitions
// ---------------------------------------------------------------------------

fun state_name(s: DeployState) : string => match s {
  Idle       => "Idle",
  Deploying  => "Deploying",
  Healthy    => "Healthy",
  Degraded   => "Degraded",
  RolledBack => "RolledBack"
}

// step: Idle -> Deploying
fun start_deploy(state: DeployState, artifact: string) : Transition =>
  match state {
    Idle => Transition {
      next: Deploying,
      log: "Deploying artifact: " + artifact
    },
    _ => Transition {
      next: state,
      log: "Cannot start deploy from state: " + state_name(state)
    }
  }

// step: Deploying -> Healthy | Degraded
fun health_check(state: DeployState, status_code: int) : Transition =>
  match state {
    Deploying =>
      if status_code == 200 {
        Transition { next: Healthy, log: "Health check passed (" + show(status_code) + ")" }
      } else {
        Transition { next: Degraded, log: "Health check failed (" + show(status_code) + ")" }
      },
    _ => Transition {
      next: state,
      log: "Cannot health-check from state: " + state_name(state)
    }
  }

// step: Degraded -> RolledBack
fun rollback(state: DeployState) : Transition =>
  match state {
    Degraded => Transition {
      next: RolledBack,
      log: "Rollback complete"
    },
    _ => Transition {
      next: state,
      log: "Cannot rollback from state: " + state_name(state)
    }
  }

// ---------------------------------------------------------------------------
// Runner — simulates a failing deploy
// ---------------------------------------------------------------------------

fun run_step(state: DeployState, t: Transition) {
  println("[" + state_name(state) + " -> " + state_name(t.next) + "] " + t.log)
  t.next
}

fun main() {
  let s0 = Idle

  // Step 1: start deploy
  let t1 = start_deploy(s0, "v1.2.3")
  let s1 = run_step(s0, t1)

  // Step 2: health check fails (simulate 503)
  let t2 = health_check(s1, 503)
  let s2 = run_step(s1, t2)

  // Step 3: rollback because degraded
  let t3 = rollback(s2)
  let s3 = run_step(s2, t3)

  println("Final state: " + state_name(s3))
}

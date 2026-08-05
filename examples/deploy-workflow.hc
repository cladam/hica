// hica — typed workflow state machine
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
// Choreo-style runner - given / when / then output
// ---------------------------------------------------------------------------

fun choreo_step(curr: DeployState, name: string, desc: string, action: string, t: Transition, prev_dep: string) : DeployState {
  println("  test " + name + " \"" + desc + "\" {")
  println("    given:")
  println("      " + prev_dep)
  println("    when:")
  println("      System run \"" + action + "\"")
  println("    then:")
  println("      System state_is \"" + state_name(t.next) + "\"  // " + t.log)
  println("  }")
  println("")
  t.next
}

fun scenario_header(name: string) {
  println("scenario \"" + name + "\" {")
  println("")
}

fun scenario_footer(final_state: DeployState) {
  println("} // final state: " + state_name(final_state))
  println("")
}

// ---------------------------------------------------------------------------
// Scenario A: deploy fails, system rolls back
// ---------------------------------------------------------------------------

fun scenario_failing_deploy() {
  scenario_header("Deploy fails and rolls back")
  let artifact = "v1.2.3"
  let s0 = Idle
  let s1 = choreo_step(s0, "StartDeploy", "Deploy the artifact " + artifact, "start_deploy(" + artifact + ")", start_deploy(s0, artifact), "Test can_start")
  let s2 = choreo_step(s1, "HealthCheck", "Perform health check on deployed artifact", "health_check(503)", health_check(s1, 503), "Test has_succeeded StartDeploy")
  let s3 = choreo_step(s2, "Rollback", "Rollback degraded deployment", "rollback()", rollback(s2), "Test has_succeeded HealthCheck")
  scenario_footer(s3)
}

// ---------------------------------------------------------------------------
// Scenario B: deploy succeeds, service is healthy
// ---------------------------------------------------------------------------

fun scenario_happy_deploy() {
  scenario_header("Deploy succeeds")
  let artifact = "v2.0.0"
  let s0 = Idle
  let s1 = choreo_step(s0, "StartDeploy", "Deploy the artifact " + artifact, "start_deploy(" + artifact + ")", start_deploy(s0, artifact), "Test can_start")
  let s2 = choreo_step(s1, "HealthCheck", "Perform health check on deployed artifact", "health_check(200)", health_check(s1, 200), "Test has_succeeded StartDeploy")
  scenario_footer(s2)
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

fun main() {
  println("feature \"Deploy service workflow\"")
  println("")
  println("actors {")
  println("  System")
  println("}")
  println("")
  scenario_failing_deploy()
  scenario_happy_deploy()
}

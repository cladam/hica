// hica — AWS Step Functions modelled as typed state machines
//
// An order processing workflow that mirrors the structure of an AWS
// Step Functions state machine, but with compile-time type safety.
//
//   Step Functions concept  |  hica equivalent
//   ------------------------|----------------------------------
//   State machine           |  type OrderState (enum)
//   Task state              |  fun returning StepResult
//   Choice state            |  if/else or match branching
//   Retry                   |  outcome: "retry", attempt: n
//   Catch                   |  outcome: "catch", -> fallback
//   Succeed (terminal)      |  outcome: "succeed"
//   Fail (terminal)         |  outcome: "fail"
//   State input/output      |  struct Order (typed, not JSON)
//
// Benefits over raw ASL JSON:
//   - State transitions type-checked at compile time
//   - Input/output shapes are structs, not untyped JSON
//   - Retry/catch patterns are reusable first-class functions
//   - Runs locally without AWS; can compile to WASM for edge
//
// Equivalent ASL JSON shown at the bottom for comparison.

// ---------------------------------------------------------------------------
// Workflow states (Step Functions: keys in "States" object)
// ---------------------------------------------------------------------------

type OrderState {
  ValidateOrder,
  ChargePayment,
  UpdateInventory,
  SendConfirmation,
  OrderFailed,
  OrderComplete
}

// ---------------------------------------------------------------------------
// Step result — encodes Next / Retry / Catch / Succeed / Fail
// ---------------------------------------------------------------------------

struct StepResult {
  next: OrderState,
  outcome: string,
  attempt: int,
  log: string
}

// ---------------------------------------------------------------------------
// Workflow context — typed data flowing between states (not JSON)
// ---------------------------------------------------------------------------

struct Order {
  order_id: string,
  amount: float,
  email: string
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

fun state_label(s: OrderState) : string => match s {
  ValidateOrder    => "ValidateOrder",
  ChargePayment    => "ChargePayment",
  UpdateInventory  => "UpdateInventory",
  SendConfirmation => "SendConfirmation",
  OrderFailed      => "OrderFailed",
  OrderComplete    => "OrderComplete"
}

fun outcome_label(r: StepResult) : string =>
  if r.outcome == "retry" {
    "Retry(attempt=" + show(r.attempt) + ") -> " + state_label(r.next)
  } else if r.outcome == "catch" {
    "Catch -> " + state_label(r.next)
  } else if r.outcome == "succeed" {
    "Succeed"
  } else if r.outcome == "fail" {
    "Fail"
  } else {
    "Next -> " + state_label(r.next)
  }

// ---------------------------------------------------------------------------
// Task states — each is a typed function, not a JSON blob
// ---------------------------------------------------------------------------

// Step Functions: Task "ValidateOrder"
//   Retry: MaxAttempts=2, Catch: -> OrderFailed
fun validate_order(order: Order, attempt: int) : StepResult =>
  if order.order_id != "" && order.amount > 0.0 {
    StepResult { next: ChargePayment, outcome: "next", attempt: 0,
                 log: "Order " + order.order_id + " validated" }
  } else if attempt < 2 {
    StepResult { next: ValidateOrder, outcome: "retry", attempt: attempt + 1,
                 log: "Invalid order, retrying" }
  } else {
    StepResult { next: OrderFailed, outcome: "catch", attempt: 0,
                 log: "Validation failed after retries" }
  }

// Step Functions: Task "ChargePayment"
//   Retry: MaxAttempts=1 (amounts > 1000 simulate a decline)
//   Catch: -> OrderFailed
fun charge_payment(order: Order, attempt: int) : StepResult =>
  if order.amount <= 1000.0 || attempt > 0 {
    StepResult { next: UpdateInventory, outcome: "next", attempt: 0,
                 log: "Payment charged: $" + show_fixed(order.amount, 2) }
  } else if attempt < 1 {
    StepResult { next: ChargePayment, outcome: "retry", attempt: attempt + 1,
                 log: "Payment declined, retrying" }
  } else {
    StepResult { next: OrderFailed, outcome: "catch", attempt: 0,
                 log: "Payment failed after retries" }
  }

// Step Functions: Task "UpdateInventory"
fun update_inventory(order: Order) : StepResult =>
  StepResult { next: SendConfirmation, outcome: "next", attempt: 0,
               log: "Inventory reserved for " + order.order_id }

// Step Functions: Task "SendConfirmation" -> Succeed
fun send_confirmation(order: Order) : StepResult =>
  StepResult { next: OrderComplete, outcome: "succeed", attempt: 0,
               log: "Confirmation sent to " + order.email }

// ---------------------------------------------------------------------------
// Choreo-style runner
// ---------------------------------------------------------------------------

fun step(curr: OrderState, task: string, r: StepResult) {
  println("  task " + task)
  println("    state:   " + state_label(curr))
  println("    outcome: " + outcome_label(r))
  println("    log:     " + r.log)
  println("")
}

fun scenario_header(name: string) {
  println("scenario \"" + name + "\" {")
  println("")
}

fun scenario_footer(r: StepResult) {
  println("} // terminal: " + outcome_label(r))
  println("")
}

// ---------------------------------------------------------------------------
// Scenario A: standard order — happy path
// ---------------------------------------------------------------------------

fun scenario_happy_path() {
  scenario_header("Standard order - happy path")
  let order = Order { order_id: "ORD-001", amount: 49.99, email: "alice@example.com" }

  let r1 = validate_order(order, 0)
  step(ValidateOrder, "validate_order", r1)

  let r2 = charge_payment(order, 0)
  step(ChargePayment, "charge_payment", r2)

  let r3 = update_inventory(order)
  step(UpdateInventory, "update_inventory", r3)

  let r4 = send_confirmation(order)
  step(SendConfirmation, "send_confirmation", r4)

  scenario_footer(r4)
}

// ---------------------------------------------------------------------------
// Scenario B: high-value order — payment retries then succeeds
// ---------------------------------------------------------------------------

fun scenario_payment_retry() {
  scenario_header("High-value order - payment retry succeeds")
  let order = Order { order_id: "ORD-002", amount: 2500.00, email: "bob@example.com" }

  let r1 = validate_order(order, 0)
  step(ValidateOrder, "validate_order", r1)

  let r2 = charge_payment(order, 0)
  step(ChargePayment, "charge_payment", r2)

  let r3 = charge_payment(order, r2.attempt)
  step(ChargePayment, "charge_payment (retry " + show(r2.attempt) + ")", r3)

  let r4 = update_inventory(order)
  step(UpdateInventory, "update_inventory", r4)

  let r5 = send_confirmation(order)
  step(SendConfirmation, "send_confirmation", r5)

  scenario_footer(r5)
}

// ---------------------------------------------------------------------------
// Scenario C: invalid order — validation catches, state machine fails
// ---------------------------------------------------------------------------

fun scenario_validation_fail() {
  scenario_header("Invalid order - validation fails")
  let order = Order { order_id: "", amount: 0.0, email: "bad@example.com" }

  let r1 = validate_order(order, 0)
  step(ValidateOrder, "validate_order", r1)

  let r2 = validate_order(order, r1.attempt)
  step(ValidateOrder, "validate_order (retry 1)", r2)

  let r3 = validate_order(order, r2.attempt)
  step(ValidateOrder, "validate_order (retry 2 - final)", r3)

  scenario_footer(r3)
}

fun main() {
  println("feature \"Order processing workflow (Step Functions model)\"")
  println("")
  scenario_happy_path()
  scenario_payment_retry()
  scenario_validation_fail()
}

// ---------------------------------------------------------------------------
// Equivalent ASL JSON — for comparison with the hica version above
//
// {
//   "Comment": "Order processing workflow",
//   "StartAt": "ValidateOrder",
//   "States": {
//     "ValidateOrder": {
//       "Type": "Task",
//       "Resource": "arn:aws:lambda:...:function:ValidateOrder",
//       "Retry": [{ "ErrorEquals": ["States.ALL"], "MaxAttempts": 2 }],
//       "Catch": [{ "ErrorEquals": ["States.ALL"], "Next": "OrderFailed" }],
//       "Next": "ChargePayment"
//     },
//     "ChargePayment": {
//       "Type": "Task",
//       "Resource": "arn:aws:lambda:...:function:ChargePayment",
//       "Retry": [{ "ErrorEquals": ["States.ALL"], "MaxAttempts": 1 }],
//       "Catch": [{ "ErrorEquals": ["States.ALL"], "Next": "OrderFailed" }],
//       "Next": "UpdateInventory"
//     },
//     "UpdateInventory": {
//       "Type": "Task",
//       "Resource": "arn:aws:lambda:...:function:UpdateInventory",
//       "Next": "SendConfirmation"
//     },
//     "SendConfirmation": {
//       "Type": "Task",
//       "Resource": "arn:aws:lambda:...:function:SendConfirmation",
//       "End": true
//     },
//     "OrderFailed": {
//       "Type": "Fail",
//       "Cause": "Order processing failed"
//     }
//   }
// }
//
// What ASL JSON cannot do that hica can:
//   - Types: Order struct catches shape mismatches at compile time,
//            not at runtime when the Lambda explodes on bad input
//   - Retry logic: spelled out as typed functions, not opaque JSON config
//   - Local execution: run the workflow without deploying to AWS
//   - Composition: reuse validate_order in other workflows by importing it
//   - Effect types: charge_payment could declare "network" effect,
//                   proving it never writes to disk
// ---------------------------------------------------------------------------

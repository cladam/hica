// hica — Config-driven workflow engine
//
// Workflow graph is loaded from HML config at runtime.
// Task logic (what each step does) lives here in typed hica code.
//
//   order-workflow.hml       — states, transitions, retry limits, catch targets
//   order-workflow-config.hc — task implementations, typed context, interpreter
//
// This mirrors how AWS Step Functions separates the state machine definition
// (ASL JSON) from the task implementations (Lambda functions):
//
//   ASL JSON   ->  order-workflow.hml       (graph)
//   Lambda fns ->  order-workflow-config.hc (logic)
//
// Change the graph in HML without touching task logic, and vice versa.

import "../lib/hml/src/hml"
import "std/datetime"

// ---------------------------------------------------------------------------
// Data types
// ---------------------------------------------------------------------------

// Workflow task definition — loaded from HML, not hardcoded
struct TaskDef {
  task_name:   string,
  on_success:  string,
  on_failure:  string,
  max_retries: int
}

// Typed context flowing through the workflow (not untyped JSON)
struct Order {
  order_id: string,
  amount:   float,
  email:    string
}

// Task execution result — typed, not a string/JSON blob
struct TaskResult {
  succeeded: bool,
  log:       string
}

// ---------------------------------------------------------------------------
// Task logic — implementations only, no routing knowledge
// Each function is pure: no awareness of what comes next.
// ---------------------------------------------------------------------------

fun validate_order(order: Order, attempt: int) : TaskResult =>
  if order.order_id != "" && order.amount > 0.0 {
    TaskResult { succeeded: true,  log: "Order " + order.order_id + " validated" }
  } else {
    TaskResult { succeeded: false, log: "Invalid order" }
  }

fun charge_payment(order: Order, attempt: int) : TaskResult =>
  if order.amount <= 1000.0 || attempt > 0 {
    TaskResult { succeeded: true,  log: "Payment charged: $" + show_fixed(order.amount, 2) }
  } else {
    TaskResult { succeeded: false, log: "Payment declined" }
  }

fun update_inventory(order: Order) : TaskResult =>
  TaskResult { succeeded: true, log: "Inventory reserved for " + order.order_id }

fun send_confirmation(order: Order) : TaskResult =>
  TaskResult { succeeded: true, log: "Confirmation sent to " + order.email }

// Dispatcher — maps task name (from config) to the matching function
fun dispatch_task(name: string, order: Order, attempt: int) : TaskResult =>
  if name == "validate_order" {
    validate_order(order, attempt)
  } else if name == "charge_payment" {
    charge_payment(order, attempt)
  } else if name == "update_inventory" {
    update_inventory(order)
  } else if name == "send_confirmation" {
    send_confirmation(order)
  } else {
    TaskResult { succeeded: false, log: "Unknown task: " + name }
  }

// ---------------------------------------------------------------------------
// HML config parsing — convert @task elements into TaskDef structs
// ---------------------------------------------------------------------------

fun parse_task(e: Hml) : TaskDef {
  let name    = match hml_attr(e, "name")        |> as_str { Some(s) => s, None => "" }
  let on_s    = match hml_attr(e, "on_success")  |> as_str { Some(s) => s, None => "" }
  let on_f    = match hml_attr(e, "on_failure")  |> as_str { Some(s) => s, None => "" }
  let retries = match hml_attr(e, "max_retries") |> as_int { Some(n) => n, None => 0 }
  TaskDef { task_name: name, on_success: on_s, on_failure: on_f, max_retries: retries }
}

fun parse_tasks(elems: list<Hml>) : list<TaskDef> {
  match elems {
    [] => [],
    [e, ..rest] => [parse_task(e)] + parse_tasks(rest)
  }
}

fun find_task(tasks: list<TaskDef>, name: string) : maybe<TaskDef> {
  match tasks {
    [] => None,
    [t, ..rest] => if t.task_name == name { Some(t) } else { find_task(rest, name) }
  }
}

// ---------------------------------------------------------------------------
// Generic workflow interpreter — driven entirely by task defs from config
// (exec_task and run_step are mutually recursive: hica detects this automatically)
// ---------------------------------------------------------------------------

// Named helper to avoid inline statement blocks inside match arms
fun exec_task(tasks: list<TaskDef>, def: TaskDef, current: string, order: Order, attempt: int) {
  let result = dispatch_task(current, order, attempt)
  let suffix = if attempt > 0 { " (retry " + show(attempt) + ")" } else { "" }
  println("  task " + current + suffix)
  println("    log:     " + result.log)
  if result.succeeded {
    println("    -> " + def.on_success)
    run_step(tasks, def.on_success, order, 0)
  } else if attempt < def.max_retries {
    println("    -> Retry " + show(attempt + 1) + "/" + show(def.max_retries) + " -> " + current)
    run_step(tasks, current, order, attempt + 1)
  } else {
    println("    -> Catch -> " + def.on_failure)
    run_step(tasks, def.on_failure, order, 0)
  }
}

// Advance one step: look up current state in loaded config, then dispatch
fun run_step(tasks: list<TaskDef>, current: string, order: Order, attempt: int) {
  match find_task(tasks, current) {
    None      => println("  [terminal: " + current + "]"),
    Some(def) => exec_task(tasks, def, current, order, attempt)
  }
}

fun run_scenario(tasks: list<TaskDef>, start: string, label: string, order: Order) {
  println("scenario \"" + label + "\" \{")
  println("")
  run_step(tasks, start, order, 0)
  println("")
  println("\}")
}

// ---------------------------------------------------------------------------
// Entry — load config from HML, then run scenarios against it
// ---------------------------------------------------------------------------

fun run_workflow(body: list<HmlNode>, wf: Hml) {
  let task_elems = hml_elems(body, "task")
  let tasks      = parse_tasks(task_elems)
  let start      = match hml_attr(wf, "start") |> as_str { Some(s) => s, None => "start" }
  println("feature \"Order workflow (config-driven)\"")
  println("  // graph loaded from examples/order-workflow.hml")
  println("")
  run_scenario(tasks, start, "Standard order - happy path",
    Order { order_id: "ORD-001", amount: 49.99,   email: "alice@example.com" })
  println("")
  run_scenario(tasks, start, "High-value order - payment retry",
    Order { order_id: "ORD-002", amount: 2500.00, email: "bob@example.com" })
  println("")
  run_scenario(tasks, start, "Invalid order - validation fails",
    Order { order_id: "",        amount: 0.0,    email: "bad@example.com" })
}

fun main() {
  match read_file("examples/order-workflow.hml") {
    Err(e) => println("Config error: " + e),
    Ok(content) => match hml_parse(content) {
      Err(e) => println("Parse error: " + e),
      Ok(nodes) => match hml_elem(nodes, "workflow") {
        None     => println("No @workflow element found in config"),
        Some(wf) => match hml_body(wf) {
          None       => println("Workflow has no body"),
          Some(body) => run_workflow(body, wf)
        }
      }
    }
  }
}

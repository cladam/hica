// hica — building pipelines
//
// Pipe (|>), UFCS, closures, and enums combine to create
// fluent, script-like processing chains — no macros or
// custom syntax needed.
import "std/string"

type Step {
  Pass(value: string, trace: string),
  Fail(reason: string)
}

// Start a pipeline: trim input and reject blanks
fun start(input: string) : Step {
  let v = input.trim()
  if v.is_empty() { Fail("empty input") }
  else { Pass(v, "start") }
}

// Chain a transformation onto a passing step
fun transform(step: Step, label: string, f) : Step =>
  match step {
    Pass(v, t) => Pass(f(v), "{t} | {label}"),
    Fail(r)    => Fail(r)
  }

// Validate — fail the pipeline if the predicate is false
fun must(step: Step, label: string, check) : Step =>
  match step {
    Pass(v, t) => if check(v) { Pass(v, "{t} | {label}: ok") }
                  else { Fail("{label} failed for '{v}'") },
    Fail(r)    => Fail(r)
  }

// Print the pipeline result
fun report(step: Step) =>
  match step {
    Pass(v, t) => println("  pass: '{v}'  [{t}]"),
    Fail(r)    => println("  FAIL: {r}")
  }

fun main() {
  let names = ["Alicia", "Love", "Claes", "so", ""]

  println("--- name pipeline ---")
  names.foreach((name) =>
    start(name)
      |> transform("lowercase",  (s) => s.to_lower())
      |> transform("capitalise", (s) => s.capitalise())
      |> must("min 3 chars", (s) => str_length(s) >= 3)
      |> report
  )
}

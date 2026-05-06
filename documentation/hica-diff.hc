// hica-diff: line diff via LCS, unified-diff format
// Uses: struct, split, var, loop, break, continue, for, string interpolation

struct DiffOp { kind: string, line: string }

struct Hunk {
  a_start: int, a_count: int,
  b_start: int, b_count: int,
  lines: list<string>
}

// Build a list of n zeros
fun zeros(n) {
  if n == 0 { [] }
  else { cons(0, zeros(n - 1)) }
}

// Build one row of the LCS dp table from the previous row
fun build_row(a_line: string, b_lines: list<string>, prev: list<int>) {
  var row: list<int> = [0]
  for jb in enumerate(b_lines) {
    let (j, bj) = jb
    let cell = if a_line == bj {
      prev[j] + 1
    } else {
      max(prev[j + 1], row[-1])
    }
    row = row + [cell]
  }
  row
}

// Build the full LCS dp table as a list of lists
fun lcs_table(a, b) {
  var table = [zeros(length(b) + 1)]
  for a_line in a {
    table = table + [build_row(a_line, b, table[-1])]
  }
  table
}

// Backtrack through dp table to produce diff ops (iterative)
fun backtrack(a, b, dp) {
  var i = length(a)
  var j = length(b)
  var ops: list<DiffOp> = []
  loop {
    if i == 0 && j == 0 { break }
    else if i > 0 && j > 0 && a[i - 1] == b[j - 1] {
      ops = cons(DiffOp { kind: "=", line: a[i - 1] }, ops)
      i = i - 1
      j = j - 1
    }
    else if j > 0 && (i == 0 || dp[i][j - 1] >= dp[i - 1][j]) {
      ops = cons(DiffOp { kind: "+", line: b[j - 1] }, ops)
      j = j - 1
    }
    else {
      ops = cons(DiffOp { kind: "-", line: a[i - 1] }, ops)
      i = i - 1
    }
  }
  ops
}

// Compute diff between two lists of lines
fun diff(a, b) {
  let dp = lcs_table(a, b)
  backtrack(a, b, dp)
}

// Format a single diff op as a prefixed line
fun format_op(op: DiffOp) : string =>
  match op.kind {
    "=" => "  {op.line}",
    "+" => "+ {op.line}",
    "-" => "- {op.line}",
    _   => op.line
  }

// Collect ops into hunks with context lines
fun collect_hunks(ops: list<DiffOp>, context: int) {
  let empty_hunk = Hunk { a_start: 0, a_count: 0, b_start: 0, b_count: 0, lines: [] }
  var hunks: list<Hunk> = []
  var hunk = empty_hunk
  var pending: list<string> = []
  var trailing = 0
  var la = 0
  var lb = 0

  for op in ops {
    match op.kind {
      "=" => {
        la = la + 1
        lb = lb + 1
        if length(hunk.lines) > 0 && trailing < context {
          hunk = Hunk {
            a_start: hunk.a_start, a_count: hunk.a_count + 1,
            b_start: hunk.b_start, b_count: hunk.b_count + 1,
            lines: hunk.lines + ["  {op.line}"]
          }
          trailing = trailing + 1
        } else if length(hunk.lines) > 0 {
          hunks = hunks + [hunk]
          hunk = empty_hunk
          pending = [op.line]
          trailing = 0
        } else {
          if length(pending) >= context {
            pending = drop(pending, 1) + [op.line]
          } else {
            pending = pending + [op.line]
          }
          trailing = 0
        }
      },
      "+" => {
        lb = lb + 1
        if length(hunk.lines) == 0 {
          let a_start = max(1, la + 1 - length(pending))
          let b_start = max(1, lb - length(pending))
          let ctx_lines = map(pending, (c) => "  {c}")
          hunk = Hunk {
            a_start: a_start, a_count: length(pending),
            b_start: b_start, b_count: length(pending) + 1,
            lines: ctx_lines + ["+ {op.line}"]
          }
        } else {
          hunk = Hunk {
            a_start: hunk.a_start, a_count: hunk.a_count,
            b_start: hunk.b_start, b_count: hunk.b_count + 1,
            lines: hunk.lines + ["+ {op.line}"]
          }
        }
        pending = []
        trailing = 0
      },
      _ => {
        la = la + 1
        if length(hunk.lines) == 0 {
          let a_start = max(1, la - length(pending))
          let b_start = max(1, lb + 1 - length(pending))
          let ctx_lines = map(pending, (c) => "  {c}")
          hunk = Hunk {
            a_start: a_start, a_count: length(pending) + 1,
            b_start: b_start, b_count: length(pending),
            lines: ctx_lines + ["- {op.line}"]
          }
        } else {
          hunk = Hunk {
            a_start: hunk.a_start, a_count: hunk.a_count + 1,
            b_start: hunk.b_start, b_count: hunk.b_count,
            lines: hunk.lines + ["- {op.line}"]
          }
        }
        pending = []
        trailing = 0
      }
    }
  }

  if length(hunk.lines) > 0 { hunks + [hunk] }
  else { hunks }
}

// Format hunks as unified diff
fun unified(a, b, path_a, path_b) {
  let ops = diff(a, b)
  let hunks = collect_hunks(ops, 3)
  let header = "--- {path_a}\n+++ {path_b}"
  var body = ""
  for h in hunks {
    let hdr = "@@ -{h.a_start},{h.a_count} +{h.b_start},{h.b_count} @@"
    let lines_str = join(h.lines, "\n") + "\n"
    body = body + hdr + "\n" + lines_str
  }
  header + "\n" + body
}

fun main() {
  let a = ["one", "two", "three", "four"]
  let b = ["one", "two", "THREE", "four", "five"]

  // Simple diff
  let ops = diff(a, b)
  for op in ops {
    println(format_op(op))
  }

  // Unified diff
  println("")
  println(unified(a, b, "a.txt", "b.txt"))
}

// Expected simple output:
//   one
//   two
// - three
// + THREE
//   four
// + five
//
// Expected unified output:
// --- a.txt
// +++ b.txt
// @@ -1,4 +1,5 @@
//   one
//   two
// - three
// + THREE
//   four
// + five

// hica-diff: line diff via LCS, unified-diff format
// Requires: split, structs, string comparison (backlog)

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
fun build_row(a_line, b_lines, prev) {
  fold(enumerate(b_lines), [0], (row, jb) => {
    let (j, bj) = jb;
    let cell = if a_line == bj {
      prev[j] + 1
    } else {
      max(prev[j + 1], row[-1])
    };
    row + [cell]
  })
}

// Build the full LCS dp table as a list of lists
fun lcs_table(a, b) {
  fold(a, [zeros(length(b) + 1)], (table, a_line) => {
    table + [build_row(a_line, b, table[-1])]
  })
}

// Backtrack through dp table to produce diff ops
fun backtrack(a, b, dp, i, j) {
  if i == 0 && j == 0 { [] }
  else if i > 0 && j > 0 && a[i - 1] == b[j - 1] {
    backtrack(a, b, dp, i - 1, j - 1) + [DiffOp { kind: "=", line: a[i - 1] }]
  }
  else if j > 0 && (i == 0 || dp[i][j - 1] >= dp[i - 1][j]) {
    backtrack(a, b, dp, i, j - 1) + [DiffOp { kind: "+", line: b[j - 1] }]
  }
  else {
    backtrack(a, b, dp, i - 1, j) + [DiffOp { kind: "-", line: a[i - 1] }]
  }
}

// Compute diff between two lists of lines
fun diff(a, b) {
  let dp = lcs_table(a, b);
  backtrack(a, b, dp, length(a), length(b))
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
fun collect_hunks(ops, context) {
  let empty_hunk = Hunk { a_start: 0, a_count: 0, b_start: 0, b_count: 0, lines: [] };
  // State: (hunks, current_hunk, pending_context, trailing, line_a, line_b)
  let result = fold(ops, ([], empty_hunk, [], 0, 0, 0), (state, op) => {
    let (hunks, hunk, pending, trailing, la, lb) = state;
    match op.kind {
      "=" => {
        let la2 = la + 1;
        let lb2 = lb + 1;
        if length(hunk.lines) > 0 && trailing < context {
          let h2 = Hunk { ...hunk,
            a_count: hunk.a_count + 1,
            b_count: hunk.b_count + 1,
            lines: hunk.lines + ["  {op.line}"]
          };
          (hunks, h2, [], trailing + 1, la2, lb2)
        } else if length(hunk.lines) > 0 {
          let new_pending = [op.line];
          (hunks + [hunk], empty_hunk, new_pending, 0, la2, lb2)
        } else {
          let new_pending = if length(pending) >= context {
            drop(pending, 1) + [op.line]
          } else {
            pending + [op.line]
          };
          (hunks, hunk, new_pending, 0, la2, lb2)
        }
      },
      "+" => {
        let lb2 = lb + 1;
        if length(hunk.lines) == 0 {
          let a_start = max(1, la + 1 - length(pending));
          let b_start = max(1, lb2 - length(pending));
          let ctx_lines = map(pending, (c) => "  {c}");
          let h2 = Hunk {
            a_start: a_start, a_count: length(pending),
            b_start: b_start, b_count: length(pending),
            lines: ctx_lines
          };
          let h3 = Hunk { ...h2,
            b_count: h2.b_count + 1,
            lines: h2.lines + ["+ {op.line}"]
          };
          (hunks, h3, [], 0, la, lb2)
        } else {
          let h2 = Hunk { ...hunk,
            b_count: hunk.b_count + 1,
            lines: hunk.lines + ["+ {op.line}"]
          };
          (hunks, h2, [], 0, la, lb2)
        }
      },
      _ => {
        let la2 = la + 1;
        if length(hunk.lines) == 0 {
          let a_start = max(1, la2 - length(pending));
          let b_start = max(1, lb + 1 - length(pending));
          let ctx_lines = map(pending, (c) => "  {c}");
          let h2 = Hunk {
            a_start: a_start, a_count: length(pending),
            b_start: b_start, b_count: length(pending),
            lines: ctx_lines
          };
          let h3 = Hunk { ...h2,
            a_count: h2.a_count + 1,
            lines: h2.lines + ["- {op.line}"]
          };
          (hunks, h3, [], 0, la2, lb)
        } else {
          let h2 = Hunk { ...hunk,
            a_count: hunk.a_count + 1,
            lines: hunk.lines + ["- {op.line}"]
          };
          (hunks, h2, [], 0, la2, lb)
        }
      }
    }
  });
  let (hunks, last_hunk, _, _, _, _) = result;
  if length(last_hunk.lines) > 0 { hunks + [last_hunk] }
  else { hunks }
}

// Format hunks as unified diff
fun unified(a, b, path_a, path_b) {
  let ops = diff(a, b);
  let hunks = collect_hunks(ops, 3);
  let header = "--- {path_a}\n+++ {path_b}";
  let body = fold(hunks, "", (out, h) => {
    let hdr = "@@ -{h.a_start},{h.a_count} +{h.b_start},{h.b_count} @@";
    let lines = fold(h.lines, "", (acc, l) => acc + l + "\n");
    out + hdr + "\n" + lines
  });
  header + "\n" + body
}

fun main() {
  let a = ["one", "two", "three", "four"];
  let b = ["one", "two", "THREE", "four", "five"];

  // Simple diff
  let ops = diff(a, b);
  foreach(ops, (op) => println(format_op(op)));

  // Unified diff
  println("");
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

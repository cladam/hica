// hishell — a history-aware interactive shell
//
// Inspired by rlwrap: demonstrates command history, recall,
// and persistence — core readline-wrapper concepts in Hica.
//
// History commands:
//   !!           repeat last command
//   !N           recall command #N from history
//   !prefix      recall last command starting with prefix
//   history      show full command history
//   history N    show last N entries
//
// Built-in commands:
//   echo TEXT    print text
//   rev TEXT     reverse text
//   upper TEXT   convert to uppercase
//   lower TEXT   convert to lowercase
//   count TEXT   count characters and words
//   cat FILE     display file contents
//   repeat N T   repeat text N times
//   help         show this help
//   exit         quit and save history
//
// Run:   hica run programs/hishell.hc
// Build: hica build programs/hishell.hc && ./programs/hishell

// ---------------------------------------------------------------------------
// History I/O
// ---------------------------------------------------------------------------

fun history_path() {
  let home = unwrap_maybe_or(get_env("HOME"), ".")
  home + "/.hishell_history"
}

fun load_history() {
  match read_file(history_path()) {
    Ok(content) => filter(lines(content), (line) => not_(is_empty(trim(line)))),
    Err(_)      => []
  }
}

fun save_history(hist: list<string>) {
  // Keep last 1000 entries
  let capped = drop(hist, max(0, length(hist) - 1000))
  write_file(history_path(), join(capped, "\n") + "\n")
}

// ---------------------------------------------------------------------------
// History lookup
// ---------------------------------------------------------------------------

fun last_entry(hist: list<string>) {
  if length(hist) == 0 { None }
  else { Some(hist[length(hist) - 1]) }
}

fun entry_at(hist: list<string>, n: int) {
  if n < 1 || n > length(hist) { None }
  else { Some(hist[n - 1]) }
}

fun search_back(hist: list<string>, pre: string) {
  find(reverse(hist), (cmd) => starts_with(cmd, pre))
}

// Try to recall a !-command: !! or !N or !prefix
fun try_recall(bang_rest: string, hist: list<string>) {
  if bang_rest == "!" { last_entry(hist) }
  else {
    match parse_int(bang_rest) {
      Some(n) => entry_at(hist, n),
      None    => search_back(hist, bang_rest)
    }
  }
}

// ---------------------------------------------------------------------------
// History display
// ---------------------------------------------------------------------------

fun show_history(hist: list<string>, count: int) {
  let total = length(hist)
  let start = max(0, total - count)
  let subset = drop(hist, start)
  foreach(enumerate(subset), (entry) => {
    let num = show(start + entry.0 + 1)
    let padded = pad_left(num, 4, " ")
    println("{padded}  {entry.1}")
  })
}

// ---------------------------------------------------------------------------
// String helpers
// ---------------------------------------------------------------------------

// Split a line into (command, args) at the first space
fun split_cmd(s: string) {
  let trimmed = trim(s)
  match index_of(trimmed, " ") {
    Some(i) => (trimmed[:i], trim(trimmed[i:])),
    None    => (trimmed, "")
  }
}

// ---------------------------------------------------------------------------
// Built-in commands
// ---------------------------------------------------------------------------

fun cmd_echo(args: string) {
  println(args)
}

fun cmd_rev(args: string) {
  if is_empty(args) { println("usage: rev TEXT") }
  else { println(join(reverse(split(args, "")), "")) }
}

fun cmd_upper(args: string) {
  if is_empty(args) { println("usage: upper TEXT") }
  else { println(to_upper(args)) }
}

fun cmd_lower(args: string) {
  if is_empty(args) { println("usage: lower TEXT") }
  else { println(to_lower(args)) }
}

fun cmd_count(args: string) {
  if is_empty(args) { println("usage: count TEXT") }
  else { println("{str_length(args)} char(s), {length(words(args))} word(s)") }
}

fun cmd_cat(args: string) {
  if is_empty(args) { println("usage: cat FILE") }
  else {
    match read_file(trim(args)) {
      Ok(content) => println(content),
      Err(msg)    => println("cat: {msg}")
    }
  }
}

fun cmd_repeat(args: string) {
  let pair = split_cmd(args)
  match parse_int(pair.0) {
    Some(n) => {
      if is_empty(pair.1) { println("usage: repeat N TEXT") }
      else { println(repeat_str(pair.1, n)) }
    },
    None => println("usage: repeat N TEXT")
  }
}

fun dispatch(cmd: string, args: string) {
  match cmd {
    "echo"   => cmd_echo(args),
    "rev"    => cmd_rev(args),
    "upper"  => cmd_upper(args),
    "lower"  => cmd_lower(args),
    "count"  => cmd_count(args),
    "cat"    => cmd_cat(args),
    "repeat" => cmd_repeat(args),
    _        => println("unknown: {cmd} (type 'help' for commands)")
  }
}

// ---------------------------------------------------------------------------
// Help
// ---------------------------------------------------------------------------

fun show_help() {
  println("hishell — history-aware interactive shell")
  println("")
  println("History:")
  println("  !!           repeat last command")
  println("  !N           recall command #N")
  println("  !prefix      find last command starting with prefix")
  println("  history      show full history")
  println("  history N    show last N entries")
  println("")
  println("Commands:")
  println("  echo TEXT    print text")
  println("  rev TEXT     reverse text")
  println("  upper TEXT   convert to uppercase")
  println("  lower TEXT   convert to lowercase")
  println("  count TEXT   count characters and words")
  println("  cat FILE     display file contents")
  println("  repeat N T   repeat text N times")
  println("  help         this help")
  println("  exit         save history and quit")
}

// ---------------------------------------------------------------------------
// Handle history expansion
// ---------------------------------------------------------------------------

fun handle_bang(line: string, hist: list<string>) {
  let bang = line[1:]
  match try_recall(bang, hist) {
    Some(recalled) => {
      println(recalled)
      let pair = split_cmd(recalled)
      dispatch(pair.0, pair.1)
      hist + [recalled]
    },
    None => {
      println("{line}: event not found")
      hist
    }
  }
}

// ---------------------------------------------------------------------------
// Handle history display
// ---------------------------------------------------------------------------

fun handle_history_n(rest: string, hist: list<string>) {
  match parse_int(rest) {
    Some(n) => show_history(hist, n),
    None    => println("usage: history [N]")
  }
}

// ---------------------------------------------------------------------------
// Main loop
// ---------------------------------------------------------------------------

fun main() {
  println("hishell 0.1.0 — type 'help' for commands, 'exit' to quit")
  var hist = load_history()
  if length(hist) > 0 {
    println("(loaded {length(hist)} history entries)")
  }
  var counter = length(hist) + 1

  loop {
    let raw = input("[{counter}] $ ")
    let line = trim(raw)

    if is_empty(line) { continue }

    // Exit
    if line == "exit" || line == ":quit" || line == ":q" {
      save_history(hist)
      println("Saved {length(hist)} entries. Goodbye!")
      exit(0)
    }

    // Help
    if line == "help" || line == ":help" {
      show_help()
      hist = hist + [line]
      counter = counter + 1
      continue
    }

    // History display (no args)
    if line == "history" {
      show_history(hist, length(hist))
      continue
    }

    // History display (with count)
    if starts_with(line, "history ") {
      handle_history_n(trim(removeprefix(line, "history ")), hist)
      continue
    }

    // History expansion: !! or !N or !prefix
    if starts_with(line, "!") {
      hist = handle_bang(line, hist)
      counter = counter + 1
      continue
    }

    // Regular command
    let pair = split_cmd(line)
    dispatch(pair.0, pair.1)
    hist = hist + [line]
    counter = counter + 1
    continue
  }
}

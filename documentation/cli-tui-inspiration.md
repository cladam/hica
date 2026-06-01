# CLI/TUI Inspiration from Linux Format

> Source: *Linux Format* magazine, tutorials by Shashank Sharma (Issues ~116–329)
> Archived at: https://linuxformat.com/archives?author_find=84

This document catalogues interesting CLI and TUI tools from the archive that are
relevant to hica — either as inspiration for standard library design, example
programs, or as tools that hica itself could eventually replicate or wrap.

---

## File Management

| Tool | Issue | Notes |
|------|-------|-------|
| **nnn** | 288 | Minimal, fast TUI file manager. Good model for a hica `fm` example program. |
| **FFF** | 249 | Even simpler single-panel file manager — shell-script-level complexity, achievable in hica. |
| **Midnight Commander** | 280 | Classic dual-pane. Demonstrates the ncurses TUI model; good target for a hica-tui showcase. |
| **Broot** | 266 | Fuzzy file finder with tree view. Interesting for a hica `find`-style library. |
| **rip2** | 323 | Safe `rm` with undelete/restore. A hica `rip` example would exercise file IO + trash logic. |

---

## Text Editors (Terminal)

| Tool | Issue | Notes |
|------|-------|-------|
| **micro** | 319 | Modern, keybinding-friendly terminal editor. Hica LSP / editor integration goal aligns here. |
| **Vim / extend Vim** | 258, 263 | Plugin ecosystem tutorial; relevant for hica-nvim strategy. |
| **VEM** | 293 | Vim with a more ergonomic keymap. Interesting minimal Vim clone as a hica example. |

---

## System Monitoring / Productivity

| Tool | Issue | Notes |
|------|-------|-------|
| **bottom** | 299 | `htop` replacement in Rust. Layout and interactivity design to study. |
| **Glances** | 262 | Python-based cross-platform system monitor. Hica equivalent could use Koka's IO. |
| **s-tui** | 279 | Stress-test and monitor CPU in terminal. Good for a hica `sysmon` example. |
| **WTF console** | 257 | Modular terminal dashboard. Interesting layout/widget design pattern. |
| **VisiData** | 298 | Spreadsheet-like TUI for CSV/JSON/etc. Very ambitious, but hica's tabular output could learn from its UX. |

---

## Calendar, Time, and To-Do

| Tool | Issue | Notes |
|------|-------|-------|
| **calcurse** | 309, 243 | Calendar + to-do TUI. Natural fit for a hica `cal` example (dates already in stdlib). |
| **Todo.txt** | 235 | Plain-text to-do format. A `todo` example in hica would exercise file IO and parsing. |
| **Watson** | 236 | Time-tracking CLI. Very achievable in hica — `start/stop/report` commands, datetime stdlib. |
| **TaskJuggler** | 131 | Full project management CLI. More ambitious; illustrates what hica package ecosystem could target. |

---

## Note-Taking, RSS, and Information

| Tool | Issue | Notes |
|------|-------|-------|
| **Newsboat** | 255 | Terminal RSS reader. Demonstrates HTTP fetch + TUI rendering — good advanced example. |
| **Buku** | 256 | Bookmark manager in terminal. Simple tag+search model achievable in hica with SQLite-like file storage. |
| **TLDR** | 281 | Simplified man pages. A hica `hica help <cmd>` that renders markdown in terminal fits this niche. |

---

## Music and Media

| Tool | Issue | Notes |
|------|-------|-------|
| **cmus** | 292 | Powerful music player TUI. Full scope is large, but a playlist manager in hica is realistic. |
| **Musikcube** | 260 | Streaming music player. Shows audio + TUI can coexist. |
| **Castero** | 283 | Podcast client TUI. Podcast fetching + playback could exercise hica's HTTP and process APIs. |

---

## Security and Encryption

| Tool | Issue | Notes |
|------|-------|-------|
| **Gopass** | 251 | CLI password manager (Go). A `pass`-style wrapper in hica using `exec` to GPG would be practical. |
| **pa** | 286 | Minimal shell-based password manager. Shows how little code is needed for this UX. |
| **Safecloset** | 306 | Hidden encrypted storage. Advanced topic but motivates hica's need for good crypto stdlib bindings. |

---

## Shell and Terminal Quality-of-Life

| Tool | Issue | Notes |
|------|-------|-------|
| **McFly** | 252 | Intelligent shell history search. Hica `history` integration idea. |
| **Fuzzy finder (fzf)** | 287 | The canonical interactive filter. A `fzf`-wrapper in hica would make many scripts more interactive. |
| **Espanso** | 268 | Text expansion tool. Shows daemon + hotkey pattern; interesting for hica scripting. |
| **Liquid Prompt** | 242 | Smart adaptive shell prompt. Design inspiration for a `hica prompt` command. |
| **Eternal Terminal** | 269 | SSH that survives disconnects. Motivates hica scripting for remote ops. |
| **Lshell** | 240 | Restricted shell for limited-access users. Interesting security model — hica sandbox idea. |

---

## File Transfer and Sync

| Tool | Issue | Notes |
|------|-------|-------|
| **Croc** | 284 | Simple peer-to-peer encrypted file transfer. A hica wrapper would exercise `exec` + progress output. |
| **termscp** | 305 | TUI SCP/SFTP client. Shows rich TUI navigation for remote filesystems. |
| **Joplin** | 318 | Note-sync CLI. Shows cloud-sync pattern in CLI form. |

---

## Drawing and Fun

| Tool | Issue | Notes |
|------|-------|-------|
| **Termpaint** | 327 | Drawing in the terminal with a TUI. Fun project; good hica showcase for escape codes / raw IO. |
| **Cool Retro Term** | 329 | Retro CRT-style terminal emulator. Less relevant to hica programs, but shows terminal rendering ambition. |
| **Boxes (ASCII art)** | 245 | ASCII box drawing around text. A `boxes` utility in hica is a realistic one-day example program. |
| **Angband** | 325 | Classic roguelike in terminal. The gold standard of TUI complexity — long-term hica ambition? |

---

## Key Themes for Hica

1. **File IO is central** — many of these tools (todo, bookmarks, RSS, music) are fundamentally
   about reading/writing structured files. Hica's stdlib needs solid file + path APIs.

2. **Exec + subprocess** — tools like Gopass and Croc are thin wrappers over external binaries.
   Hica's `exec`/`run` facilities should make this pattern ergonomic.

3. **Structured output** — VisiData and Glances show that tabular/tree rendering matters.
   A hica `table` stdlib function (like `rich` in Python) would unlock many of these.

4. **TUI vs. plain CLI** — most tools here are interactive TUIs, but hica currently targets
   non-interactive CLI scripts. A hica TUI library (wrapping ncurses or notcurses via FFI)
   would be the unlock for the more ambitious tools on this list.

5. **Incremental complexity** — start with Watson (time tracking) and Todo.txt (flat file),
   progress toward Newsboat (HTTP) and eventually cmus (audio + TUI).

---

---

## More Tools from Terminal Trove

> Source: https://terminaltrove.com/list/
> A curated selection of the most hica-relevant entries from ~500+ listed tools.

### Data Viewing and Querying

| Tool | Description | Hica relevance |
|------|-------------|----------------|
| **csvlens** | CSV viewer like `less` | A hica `csvlens` example would exercise streaming output + column alignment |
| **tabiew** | TUI for tabular data (CSV/TSV/Parquet/JSON) | Target UX for a hica `table` stdlib output function |
| **jless** | Command-line JSON viewer (foldable tree) | Shows what hica's `json pretty-print` could look like with folding |
| **jnv** | Interactive JSON filter using jq | Hica + jq-like DSL is an interesting direction for data scripts |
| **fx** | Terminal JSON viewer + processor | Minimal and hackable — similar spirit to hica |
| **otree** | View JSON/YAML/TOML as TUI tree | Natural fit once hica has a TOML/YAML stdlib |
| **visidata** | Terminal spreadsheet multitool | Gold standard for terminal data UX; study its keybindings |
| **sheets** | Minimal terminal spreadsheet + CSV viewer | More achievable scope than VisiData for a hica example |
| **miller** | Swiss-army knife for CSV/JSON/NDJSON data | Shows breadth of what structured-data pipelines can look like |
| **qo** | Interactive TUI to query JSON/CSV/TSV with SQL | A hica `query` example using pattern matching over lists |

---

### Notes, Journals, and Writing

| Tool | Description | Hica relevance |
|------|-------------|----------------|
| **jrnl** | Collect thoughts and notes from the command line | Simple append-to-file + date tagging — very achievable in hica |
| **rucola** | Terminal markdown note manager | Markdown-first notes with tagging; natural hica example |
| **glues** | Vim-inspired, privacy-first TUI note app | Multi-storage backend pattern to study |
| **tui-journal** | Journal app for terminal users | Shows how a CRUD TUI can be structured |
| **caps-log** | Small TUI journaling tool | Minimal scope; great first hica TUI example if we add ncurses FFI |
| **dawn** | Distraction-free terminal writing environment | Motivates a hica `write` mode with minimal UI |
| **nkt** | Note taking in the terminal | Ultra-minimal; study as counterpoint to rucola |
| **fuzpad** | Minimalistic note management powered by fzf | Shows fzf integration pattern for hica scripts |
| **ekphos** | Lightweight markdown research tool (Obsidian-inspired) | Offline-first, local markdown — good hica niche |

---

### Time, Tasks, and Finance

| Tool | Description | Hica relevance |
|------|-------------|----------------|
| **omm** | Keyboard-driven task manager | Clean UX design to emulate for a hica `tasks` example |
| **dooit** | TUI todo manager | More feature-rich than Todo.txt; comparison target |
| **dijo** | Scriptable curses-based habit tracker | Habit data is simple CSV; achievable in hica |
| **basilk** | TUI task manager with kanban logic | Kanban column layout = TUI rendering challenge for hica |
| **kanban-tui** | Customizable kanban task manager | Same; good to compare both implementations |
| **tock** | Time tracking CLI | Direct competitor/inspiration for hica `timelog` example |
| **zeit** | Simple CLI time tracker | Even simpler than Watson; start/stop + report pattern |
| **tasktimer** | Dead simple TUI task timer | Shows how minimal a useful timer CLI can be |
| **pomo** | Terminal Pomodoro timer | 25-min countdown + notifications — exercises hica's time stdlib |
| **bagels** | Expense tracker in the terminal | Structured ledger file + CLI query; achievable in hica |
| **moneyterm** | TUI expense and budget tracker | Richer than bagels; natural progression |
| **hledger-ui** | Plain text accounting TUI | The serious end of personal finance; motivates ledger format parsing |
| **cashd** | Fast and cozy personal finance TUI | Shows polish level for finance apps |

---

### Presentations and Markdown Rendering

| Tool | Description | Hica relevance |
|------|-------------|----------------|
| **slides** | Terminal presentation tool (markdown) | Shows how markdown → terminal rendering works |
| **presenterm** | TUI markdown slideshow | Most polished of the group; sets the bar |
| **patat** | Terminal presentations using Pandoc | Pandoc dependency interesting; hica could target similar output |
| **mdp** | Command-line markdown presentation | Minimal implementation to study |
| **kyma** | Terminal presentations with animated transitions | Motivates terminal animation via ANSI escape sequences |
| **glow** | Render markdown on CLI with pizzazz | Hica's `--help` output could learn from glow's rendering style |
| **frogmouth** | Markdown browser for terminal | Navigation + rendering; what hica docs browsing could look like |
| **mdcat** | Fancy cat for markdown | Simpler version of glow — good model for a hica `hcat` command |

---

### Git and Version Control

| Tool | Description | Hica relevance |
|------|-------------|----------------|
| **lazygit** | Simple terminal UI for git commands | The canonical lazy-* TUI pattern; study its workflow model |
| **gitui** | Blazing fast TUI for git in Rust | Performance-first design; comparison target for hica-speed claims |
| **tig** | Text-mode interface for git | Classic, minimal — the baseline all git TUIs are measured against |
| **gitu** | TUI git client inspired by Magit | Magit-inspired workflow; shows emacs-style command dispatch |
| **serie** | Rich git commit graph in terminal | Shows what commit visualization can look like |
| **delta** | Viewer for git and diff output | Syntax-aware diff coloring; hica `diff` output formatting target |
| **difftastic** | Structural diff that understands syntax | AST-aware diffing — advanced, but motivates hica's syntax awareness |
| **critique** | Terminal UI for reviewing git diffs | Shows interactive diff review UX |

---

### Calculators and Math

| Tool | Description | Hica relevance |
|------|-------------|----------------|
| **eva** | Calculator REPL similar to bc | A hica `calc` REPL is very achievable — exercises the parser |
| **fend** | Arbitrary-precision unit-aware calculator | Unit conversions; motivates a hica units stdlib |
| **kalker** | Scientific terminal calculator with math syntax | Shows what a math-first syntax looks like in terminal |
| **numbat** | High-precision calculator with physical units | The most ambitious; Rust-based, good comparison for hica's type system |
| **bcal** | Bits, bytes and address calculator | Low-level calculator for sysadmins; hica `bcal` example |

---

### HTTP / API Clients

| Tool | Description | Hica relevance |
|------|-------------|----------------|
| **posting** | Powerful HTTP client in terminal | Postman-like TUI — shows what hica's HTTP stdlib enables |
| **atac** | API client (Postman-like) in terminal | Collection-based API testing; hica equivalent would use `.hc` files |
| **hurl** | Run and test HTTP requests with plain text | Plain-text format resonates with hica philosophy |
| **slumber** | Terminal-based HTTP/REST client | File-based request storage — natural hica idiom |
| **httplab** | Inspect HTTP requests and mock responses | Shows testing/debugging angle for HTTP tools |
| **nexus** | Terminal HTTP client for API testing | Minimal; easier scope for a hica HTTP example |
| **curlie** | Power of curl, ease of httpie | Good UX target for hica's `http_get`/`http_post` stdlib wrappers |

---

### Log Viewing and Processing

| Tool | Description | Hica relevance |
|------|-------------|----------------|
| **lnav** | ncurses-based log file viewer | Feature-rich; sets expectations for what log viewing looks like |
| **tailspin** | Log file highlighter | Simple pattern-based coloring — achievable as a hica `highlight` util |
| **toolong** | View, tail, merge, search log files + JSONL | Multi-file log merging is a useful hica example |
| **hl** | Fast and powerful log viewer/processor | Shows structured log parsing pipeline |
| **logmerger** | View multiple log files with merged timeline | Timeline merge is interesting algorithmic challenge in hica |

---

### Regex and Text Processing

| Tool | Description | Hica relevance |
|------|-------------|----------------|
| **rexi** | Terminal UI for regex testing | A hica `rexi` would make a fun REPL example program |
| **grex** | Generate regex from user-provided test cases | Shows reverse-engineering approach; motivates hica regex stdlib |
| **trex** | Terminal app for regex visualization | Interactive regex = REPL territory for hica |
| **sttr** | CLI/TUI for 30+ string transformations | Shows the breadth of string operations users want; guides hica stdlib |
| **sd** | Intuitive find & replace (sed alternative) | Simple, well-scoped; hica `replace` stdlib function target |
| **scooter** | Interactive find and replace in terminal | Interactive version; good TUI example |

---

### Shell Productivity and Pipelines

| Tool | Description | Hica relevance |
|------|-------------|----------------|
| **up** | Write Linux pipes with instant live preview | Motivates hica's pipeline-friendly design |
| **rura** | Interactive TUI scratchpad for shell pipelines | Shows interactive pipeline building — hica REPL territory |
| **navi** | Interactive cheatsheet tool | Hica `hica help` could learn from navi's discoverability model |
| **pet** | Simple command-line snippet manager | Snippet storage + fuzzy retrieval; achievable hica example |
| **hoard** | CLI command organizer | Similar to pet but different UX; compare both |
| **just** | Command runner (Makefile alternative) | Similar niche to hica scripts; interesting positioning comparison |
| **mprocs** | Run multiple commands in parallel | Parallel process management; hica's concurrency story aligns |
| **atuin** | Sync, search and backup shell history | Shows what investing in shell history UX returns |

---

### Terminal Multiplexers and Workspace

| Tool | Description | Hica relevance |
|------|-------------|----------------|
| **zellij** | Terminal workspace with batteries included | Most modern multiplexer; shows plugin/layout architecture |
| **tmux** | The standard terminal multiplexer | Any hica TUI that wants persistent sessions needs tmux awareness |
| **byobu** | Text-based window manager and terminal multiplexer | Layered on tmux; shows UX wrapper pattern |
| **cy** | Time-traveling terminal multiplexer | Recording/replay of terminal sessions — novel concept |

---

### Fun and Creative

| Tool | Description | Hica relevance |
|------|-------------|----------------|
| **cmatrix** | Matrix-like effect in terminal | Classic; a hica `cmatrix` would show off ANSI escape code control |
| **durdraw** | Versatile ASCII and ANSI art editor | Shows the full extent of terminal drawing APIs |
| **terminaltexteffects** | Inline visual effects in terminal | Motivates a hica `effects` library for fun output animations |
| **runal** | Creative coding environment for terminal | Generative art in terminal — hica as creative coding language? |
| **astroterm** | Terminal-based star map | Data visualization (lat/lon + time → star positions) in terminal |
| **mapscii** | The whole world in your console | Shows what geo-spatial rendering in terminal looks like |
| **sigye** | Beautiful terminal clock with ASCII art fonts | ASCII font rendering; achievable in hica as a `clock` example |
| **ttyper** / **tukai** / **typioca** | Typing speed testers in terminal | A hica typing test would exercise timer, stdin reading, and rendering |
| **chess-tui** | Play chess in terminal | Shows game-loop + board rendering — advanced hica TUI example |
| **gittype** | Typing game using your source code | Clever concept; a hica version could use hica source files |

---

### Stdlib and Language Design Signals

These tools suggest features the hica standard library should prioritize:

| Signal | Tools demonstrating the need |
|--------|------------------------------|
| **Rich terminal output** (colors, boxes, tables) | glow, presenterm, delta, tailspin, terminaltexteffects |
| **Fuzzy filtering over lists** | fzf (already known), navi, pet, television, peco |
| **Structured file formats** (read/write TOML, YAML, CSV, JSON) | otree, jless, csvlens, miller, hurl |
| **Date/time arithmetic** | tock, zeit, pomo, jrnl, calcurse |
| **HTTP requests** (GET/POST, headers, JSON body) | hurl, curlie, posting, atac |
| **Process spawning and output capture** | mprocs, up, rura, just |
| **Interactive input** (readline-like, arrow keys) | navi, fzf, rexi, rura |
| **Regex matching** | grex, rexi, trex, ripgrep |

---

## Suggested Hica Example Programs (ordered by effort)

| Program | Inspired by | Effort |
|---------|-------------|--------|
| `boxes` | Boxes (LXF 245) | 1 day |
| `rip` | rip2 (LXF 323) | 2 days |
| `todo` | Todo.txt (LXF 235) + dooit | 2 days |
| `timelog` | Watson (LXF 236) + tock | 3 days |
| `bookmarks` | Buku (LXF 256) | 3 days |
| `jrnl` | jrnl (Terminal Trove) | 2 days |
| `pomo` | pomo (Terminal Trove) | 2 days |
| `calc` | eva / fend (Terminal Trove) | 3 days |
| `hcat` | mdcat / glow (Terminal Trove) | 3 days |
| `cal` | calcurse (LXF 309) + calcure | 4 days |
| `sttr` | sttr (Terminal Trove) | 4 days |
| `habits` | dijo (Terminal Trove) | 4 days |
| `sysmon` | bottom / btop / Glances | 1 week |
| `http` | hurl / posting (Terminal Trove) | 1 week |

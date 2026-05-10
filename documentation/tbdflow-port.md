# Porting tbdflow to Hica

## Overview

[tbdflow](https://github.com/cladam/tbdflow) is a CLI tool that codifies trunk-based development best practices as a git wrapper. It's currently written in Rust (~10K+ LoC, 10+ commands). This document plans a port to Hica — both as a real-world validation of the language and as a showcase project.

## What Hica already has

| Capability | Hica support |
|---|---|
| Execute git commands | `run_system()`, `run_system_read()` |
| CLI parsing (subcommands, flags, options) | `prelude/cli.hc` — clap-inspired |
| String processing (parse git output) | `split`, `lines`, `trim`, `contains`, `starts_with`, etc. |
| File I/O (config, intent log) | `read_file`, `write_file`, `read_lines` |
| Environment variables | `get_env()` |
| Interactive prompts | `input()` |
| Error handling | `result<a,b>`, `maybe<a>`, pattern matching |
| Compiles to native binary | Via Koka → C → binary |

## What Hica lacks — libraries needed

These gaps should be filled by writing **pure Hica libraries** (not Koka shims), making them reusable for the broader ecosystem.

### 1. YAML parser (`lib/yaml.hc`) — **BLOCKING for Phase 1**

tbdflow reads `.tbdflow.yml` and `.dod.yml` for configuration. Without a YAML parser, the port either uses a different config format (breaking compatibility) or can't read existing configs.

**Minimum viable scope:**
- Parse flat `key: value` pairs
- Parse lists (`- item`)
- Parse nested maps (indentation-based)
- Ignore comments (`#`)
- Return a tree structure (e.g. `enum Yaml { YStr(s), YList(items), YMap(entries) }`)

**Not needed initially:** anchors/aliases, multi-line blocks, flow syntax `{a: b}`, tags.

### 2. JSON parser/writer (`lib/json.hc`) — **BLOCKING for Phase 2–3**

The intent log is stored in `.tbdflow-intent.json`. WIP Guard snapshots also use JSON.

**Minimum viable scope:**
- Parse JSON strings, numbers, booleans, null, arrays, objects
- Write/serialize back to JSON string
- Return a tree structure (e.g. `enum Json { JStr(s), JNum(n), JBool(b), JNull, JArr(items), JObj(entries) }`)

### 3. Date/time helpers (`lib/datetime.hc`) — **NEEDED for Phase 2+**

Stale branch warnings, radar timestamps, and WIP Guard all need time awareness.

**Minimum viable scope:**
- Get current timestamp (shell out to `date +%s` or similar)
- Parse ISO 8601 timestamps from git log output
- Duration comparison ("older than 1 day")
- Format for display

### 4. Regex / pattern matching (`lib/glob.hc`) — **NEEDED for Phase 4**

Commit linting uses patterns like `^[A-Z]+-\d+$`. Radar ignore patterns and review rules use globs.

**Minimum viable scope:**
- Simple glob matching (`*`, `**`, `?`) for file patterns
- Basic regex subset for commit linting (anchors, character classes, quantifiers)

### 5. HTTP client — **NOT needed**

tbdflow shells out to `gh` (GitHub CLI) for all GitHub interactions. The Hica port can do the same — no HTTP library required.

## Phased Implementation Plan

### Phase 1 — Core daily workflow
**Prereq:** YAML parser (or use simpler config format to start)

1. `tbdflow commit` — conventional commit with pull/rebase/push on main
2. `tbdflow sync` — pull with rebase, show recent changes
3. `tbdflow status` — working directory status
4. `tbdflow current-branch` — show current branch
5. Config loader — read `.tbdflow.yml`

**Deliverable:** Enough to dogfood daily.

### Phase 2 — Branch lifecycle
**Prereq:** JSON parser (for intent log persistence)

6. `tbdflow branch` — create short-lived branches
7. `tbdflow complete` — merge + cleanup branches
8. `tbdflow check-branches` — stale branch warnings

### Phase 3 — Intent system

9. `tbdflow task` — start/show/clear tasks
10. `tbdflow note` / `+` / `n` — breadcrumb notes
11. Auto-append intent log to commit body
12. WIP Guard snapshots

### Phase 4 — Advanced features
**Prereq:** Glob matching, date/time

13. `tbdflow undo` — smart revert
14. `tbdflow changelog` — generate from conventional commits
15. `tbdflow radar` — trunk health dashboard
16. DoD checklist (`.dod.yml`)
17. Commit message linting

## Library Priority

| Library | Blocks | Complexity | Ecosystem value |
|---|---|---|---|
| `lib/yaml.hc` | Phase 1 | Medium | High — every CLI tool needs config |
| `lib/json.hc` | Phase 2–3 | Medium | High — universal data format |
| `lib/datetime.hc` | Phase 2+ | Low | Medium — common utility |
| `lib/glob.hc` | Phase 4 | Low–Medium | Medium — file matching |

Building these as standalone Hica libraries means any Hica program can use them — not just tbdflow.

## Open Questions

- **Config compatibility:** Should the Hica port read the same `.tbdflow.yml` files as the Rust version, or define its own format? YAML compat is harder but more useful.
- **Binary name:** Ship as `tbdflow` (drop-in replacement) or `tbdflow-hc` (coexist)?
- **Interactive wizard:** The Rust version has an interactive mode. Hica has `input()` — enough for simple prompts, but TUI-style selection menus would need work.
- **Monorepo support:** Adds complexity. Defer to Phase 4+?

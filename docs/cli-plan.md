# Hica CLI Plan

Modeled after Cargo and [Lisette's CLI](lisette-main/docs/intro/quickstart.md).

### Phase 2: deeper check + diagnostics
- Wire up type checker in `hica check` once `semantics/checker.kk` is implemented
- Structured error output with spans and source snippets

### Phase 3: project management
- `hica new <name>` — scaffolds a project directory with `src/main.hc`
- `hica init` — scaffolds in existing directory

### Phase 4: test runner
- `hica test` / `hica t` — discover and run `.hc` test files

### Technical Notes
- Short aliases follow Cargo convention: `b`=build, `r`=run, `c`=check, `t`=test

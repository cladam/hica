# Changelog draft — v0.29.3

### Features

- feat: add hica-lisp as a git submodule
- feat: add repeat_expr to tree-sitter-hica grammar
- feat: add hica-nvim plugin and tree-sitter-hica grammar with 0 parse errors
- feat: add support for neovim and scaffold a tree-sitter for hica
- feat: hica clean --cache + auto-invalidate stale stdlib .kk files
- feat: add stdlib gaps: std/list helpers, std/env module, random_float
- feat: rebuild playground with stdlib support and std/string
- feat: add ilseon theme colours to std/term
- feat: add -o to hica build
- feat: changed hica.ini to HML format – drinking my own Champagne

### Bug fixes

- fix: add effectful primitives
- fix: add exec_lines on top of exec
- fix: fix hica clean command to read hica.ml properly
- fix: fix highlights.scm: remove ; from punctuation (it is an extra)
- fix: fix highlights.scm: query break/continue by node type
- fix: fix textobjects.scm anchor patterns for nvim 0.12
- fix: fix multiline let init codegen — val x =\n indent-all(init)
- fix: remove generated files from .gitattributes
- fix: pinning right versions of Ruby libs, failing CI

### Docs

- docs: change theme to match main site
- docs: small fix in repl doc
- docs: update developer guide with new scripts
- docs: update docs for std/env, list helpers, random_float
- docs: cleanup prelude dir and update docs for stdlib migration
- docs: update hica's backlog with items for libraries

### Refactors

- refactor: refactor: move prelude CLI  to std/cli
- refactor: move CLI library to std/cli
- refactor: move datetime helpers to std/datetime
- refactor: move process_messages to std/actor
- refactor: move io helpers to std/io, fix codegen warnings
- refactor: move extended strings to std/string, add playground stdlib support
- refactor: move list extras to std/list, remove from auto-loaded prelude
- refactor: move operators to std/ops, remove from auto-loaded prelude
- refactor: support optional imports from the stdlib, like term

### Tests & CI

- test: add choreo test for the REPL, updated CI build
- ci: create Makefile and  update CI + devekoper guide

### Chores

- chore: clean up tree-sitter-hica conflicts, update hica-nvim README
- chore: publish new minor, extend stdlib, updated docs and a Makefile
- chore: publish new minor, fixes and better stdlib structure
- chore: publish new minor with CLI and dependencies improvement


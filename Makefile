# hica Makefile
# Common targets for building, bundling, testing, and the playground.

KOKA       = koka
HICA       = ./hica
SRC_MAIN   = src/main.kk
KLAP       = lib/klap
KUNIT      = lib/kunit
SRC        = src
CURL_LIB   = $(if $(filter Windows_NT,$(OS)),libcurl,curl)

.PHONY: all build release bundle bundle-prelude bundle-stdlib bundle-kk-stdlib test test-lexer \
        test-parser test-codegen test-effects test-cli test-js test-repl playground clean \
		choreo-cli choreo-repl submodules

# ── Default ──────────────────────────────────────────────────────────────────

all: build

# ── Submodules ────────────────────────────────────────────────────────────────

## Initialise and update all git submodules (klap, kunit, …)
submodules:
	git submodule update --init --recursive

## Guard: abort with a helpful message if klap is not initialised
check-submodules:
	@test -f $(KLAP)/klap.kk || \
	  (echo "ERROR: submodule lib/klap is missing." && \
	   echo "Run: git submodule update --init --recursive" && exit 1)

# ── Build ─────────────────────────────────────────────────────────────────────

## Debug build (fast, no optimisations)
build: check-submodules
	$(KOKA) -i$(KLAP) -i$(SRC) --cclib=$(CURL_LIB) $(KOKA_EXTRA_FLAGS) $(SRC_MAIN) -o hica
	chmod +x $(HICA)

## Optimised release build
release: check-submodules
	$(KOKA) -O2 -i$(KLAP) -i$(SRC) -v0 --cclib=$(CURL_LIB) $(KOKA_EXTRA_FLAGS) $(SRC_MAIN) -o hica
	chmod +x $(HICA)

# ── Bundle ────────────────────────────────────────────────────────────────────

## Bundle prelude + stdlib, then do a release build
bundle: bundle-prelude bundle-stdlib bundle-kk-stdlib release

## Embed prelude .hc files into src/prelude-bundle.kk
bundle-prelude:
	bash scripts/bundle-prelude.sh

## Embed stdlib .hc files into src/stdlib-bundle.kk
bundle-stdlib:
	bash scripts/bundle-stdlib.sh

## Embed native Koka stdlib files into src/stream-kk-bundle.kk
bundle-kk-stdlib:
	bash scripts/bundle-kk-stdlib.sh

# ── Tests ─────────────────────────────────────────────────────────────────────

## Run all test suites (lexer, parser, codegen, CLI e2e, JS backend, REPL)
test:
	bash test-hica.sh

## Lexer unit tests
test-lexer:
	$(KOKA) -i$(KUNIT) -i$(KLAP) -i$(SRC) -v0 -e tests/test-lexer.kk

## Parser unit tests
test-parser:
	$(KOKA) -i$(KUNIT) -i$(KLAP) -i$(SRC) -v0 -e tests/test-parser.kk

## Analyser unit tests
test-analyser:
	$(KOKA) -i$(KUNIT) -i$(KLAP) -i$(SRC) -v0 -e tests/test-analyser.kk

## Codegen unit tests
test-codegen:
	$(KOKA) -i$(KUNIT) -i$(KLAP) -i$(SRC) -v0 -e tests/test-codegen.kk

## Effects tests (user-facing algebraic effects — journal in documentation/effects-journal.md)
test-effects:
	$(KOKA) -i$(KUNIT) -i$(KLAP) -i$(SRC) -e tests/test-effects.kk

## Named-effects tests (v2 — journal in documentation/named-effects-journal.md)
## N4 imports `main` for `discover-effects`, which transitively pulls in
## the curl-based deps/http modules — so we need to link libcurl here too.
test-named-effects:
	$(KOKA) -i$(KUNIT) -i$(KLAP) -i$(SRC) --cclib=$(CURL_LIB) -e tests/test-named-effects.kk


## End-to-end CLI tests (requires a built binary)
test-cli: $(HICA)
	$(KOKA) -i$(KUNIT) -i$(KLAP) -i$(SRC) -v0 -e tests/test-cli.kk -- $(HICA)

## JS backend tests (requires a built binary)
test-js: $(HICA)
	bash tests/test-js.sh $(HICA)

## REPL choreography tests (requires a built binary)
test-repl: $(HICA)
	bash tests/test-repl.sh $(HICA)

# -- Choreo ATDD tests ---------------------------------------------------------

choreo-cli:
	choreo run -f tests/choreo/test-hica-cli.chor

choreo-repl:
	choreo run -f tests/choreo/test-hica-repl.chor

# ── Playground ────────────────────────────────────────────────────────────────

## Build the browser-based hica playground (requires koka + npx/esbuild)
playground:
	bash scripts/build-playground.sh

## Serve the playground locally on port 8080
playground-serve: playground
	cd playground && python3 -m http.server 8080

# ── Housekeeping ──────────────────────────────────────────────────────────────

## Remove the hica binary and clear the stdlib runtime cache
clean:
	rm -f hica
	rm -f ~/.hica/stdlib/*.hc ~/.hica/stdlib/*.kk

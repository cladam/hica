# Hica Makefile
# Common targets for building, bundling, testing, and the playground.

KOKA       = koka
HICA       = ./hica
SRC_MAIN   = src/main.kk
KLAP       = lib/klap
KUNIT      = lib/kunit
SRC        = src
CURL_LIB   = $(if $(filter Windows_NT,$(OS)),libcurl,curl)

.PHONY: all build release bundle bundle-prelude bundle-stdlib test test-lexer \
        test-parser test-codegen test-cli test-js test-repl playground clean \
		choreo-cli choreo-repl

# ── Default ──────────────────────────────────────────────────────────────────

all: build

# ── Build ─────────────────────────────────────────────────────────────────────

## Debug build (fast, no optimisations)
build:
	$(KOKA) -i$(KLAP) -i$(SRC) --cclib=$(CURL_LIB) $(KOKA_EXTRA_FLAGS) $(SRC_MAIN) -o hica
	chmod +x $(HICA)

## Optimised release build
release:
	$(KOKA) -O2 -i$(KLAP) -i$(SRC) -v0 --cclib=$(CURL_LIB) $(KOKA_EXTRA_FLAGS) $(SRC_MAIN) -o hica

# ── Bundle ────────────────────────────────────────────────────────────────────

## Bundle prelude + stdlib, then do a release build
bundle: bundle-prelude bundle-stdlib release

## Embed prelude .hc files into src/prelude-bundle.kk
bundle-prelude:
	bash scripts/bundle-prelude.sh

## Embed stdlib .hc files into src/stdlib-bundle.kk
bundle-stdlib:
	bash scripts/bundle-stdlib.sh

# ── Tests ─────────────────────────────────────────────────────────────────────

## Run all test suites (lexer, parser, codegen, CLI e2e, JS backend, REPL)
test:
	bash test-hica.sh

## Lexer unit tests
test-lexer:
	$(KOKA) -i$(KUNIT) -i$(SRC) -v0 -e tests/test-lexer.kk

## Parser unit tests
test-parser:
	$(KOKA) -i$(KUNIT) -i$(SRC) -v0 -e tests/test-parser.kk

## Codegen unit tests
test-codegen:
	$(KOKA) -i$(KUNIT) -i$(SRC) -v0 -e tests/test-codegen.kk

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

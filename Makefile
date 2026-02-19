.PHONY: build install spec spec-all spec-provider spec-provider-record spec-interactive clean format docs build-examples update-submodules sync-vendor-examples golden-examples

# Crystal cache for faster builds
export CRYSTAL_CACHE_DIR := $(PWD)/.crystal-cache

# Example source files and their output binaries
EXAMPLE_SOURCES := $(shell find examples -name '*.cr' -type f)
EXAMPLE_BINARIES := $(EXAMPLE_SOURCES:.cr=)
VENDOR_EXAMPLES := bubbletea bubblezone lipgloss x
CRYSTAL_FLAGS ?= -Dpreview_mt -Dexecution_context

# Build the library (check for errors)
build:
	crystal build src/term2.cr -Dpreview_mt -Dexecution_context

install:
	GIT_CONFIG_GLOBAL=/dev/null shards install

update:
	GIT_CONFIG_GLOBAL=/dev/null shards update

# Update all submodules to latest commits
update-submodules:
	git submodule update --remote --recursive
	@echo "Updated all submodules to latest commits"

# Copy Go vendor examples into examples/<vendor> for porting reference.
sync-vendor-examples:
	@for v in $(VENDOR_EXAMPLES); do \
		if [ -d vendor/$$v/examples ]; then \
			mkdir -p examples/$$v; \
			rsync -a vendor/$$v/examples/ examples/$$v/; \
			printf "Synced vendor/$$v/examples -> examples/$$v/\n"; \
		fi; \
	done

# Run all tests (excluding interactive)
spec:
	crystal spec -Dpreview_mt -Dexecution_context --tag "~interactive" --verbose

# Run all tests including interactive
spec-all:
	crystal spec -Dpreview_mt -Dexecution_context

# Run provider-specific tests
spec-provider:
	crystal spec -Dpreview_mt -Dexecution_context --tag provider

# Record HTTP fixtures for provider tests
spec-provider-record:
	HTTP_RECORD=1 crystal spec -Dpreview_mt -Dexecution_context --tag provider

# Run interactive tests (requires real terminal)
spec-interactive:
	WITH_TERMINAL=1 crystal spec -Dpreview_mt -Dexecution_context --tag interactive

# Format all Crystal files
format:
	crystal tool format

# Generate documentation
docs:
	crystal docs

# Build all examples (output in examples/ directory)
build-examples: $(EXAMPLE_BINARIES)
	@echo "Built all examples in examples/"

# Build Go and Crystal examples (output in build/)
verify-examples:
	crystal run scripts/build_examples.cr -- --all

# Clean built Go and Crystal examples
verify-examples-clean:
	crystal run scripts/build_examples.cr -- --clean

examples/%: examples/%.cr
	crystal build $(CRYSTAL_FLAGS) $< -o $@

# Generate Go goldens for example parity tests
golden-examples:
	@set -e; \
	for script in scripts/golden/gen_*_golden.sh; do \
		if [ -x "$$script" ]; then \
			echo "Running $$script"; \
			"$$script"; \
		fi; \
	done

# Clean temporary files, logs, and build artifacts
clean:
	-rm -rf temp/*
	-rm -rf log/*
	-rm -rf .crystal-cache
	-find . -name "*.dwarf" -not -path "./.git/*" -not -path "./vendor/*" -delete
	rm -f $(EXAMPLE_BINARIES)
	@echo "Cleaned temp/, log/, .crystal-cache/, all .dwarf files, and example binaries"

# Run benchmarks
benchmark:
	crystal run benchmarks/benchmark.cr --release

# Run a specific example
run-example:
	@if [ -z "$(EXAMPLE)" ]; then \
		echo "Usage: make run-example EXAMPLE=basic_example"; \
		echo "Available examples:"; \
		ls -1 examples/*.cr | xargs -n1 basename | sed 's/.cr$$//'; \
	else \
		crystal run examples/$(EXAMPLE).cr; \
	fi

# Help
help:
	@echo "Term2 - Crystal Terminal Library"
	@echo ""
	@echo "Available targets:"
	@echo "  build              - Build the library"
	@echo "  build-examples     - Build all examples (output in examples/)"
	@echo "  verify-examples    - Build Go & Crystal examples (output in build/)"
	@echo "  install            - Install dependencies"
	@echo "  update-submodules  - Update submodules to latest commits"
	@echo "  spec               - Run tests (excluding interactive)"
	@echo "  spec-all           - Run all tests"
	@echo "  spec-interactive   - Run interactive tests"
	@echo "  format             - Format Crystal files"
	@echo "  docs               - Generate documentation"
	@echo "  golden-examples    - Generate Go goldens for example parity tests"
	@echo "  clean              - Clean temp/, log/, cache, and built examples"
	@echo "  benchmark          - Run performance benchmarks"
	@echo "  run-example        - Run an example (EXAMPLE=name)"
	@echo "  help               - Show this help"

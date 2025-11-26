.PHONY: build install spec spec-all spec-provider spec-provider-record spec-interactive clean format docs

# Crystal cache for faster builds
export CRYSTAL_CACHE_DIR := $(PWD)/.crystal-cache

# Build the library (check for errors)
build:
	shards build

# Install dependencies
install:
	shards install

# Run all tests (excluding interactive)
spec:
	crystal spec --tag "~interactive"

# Run all tests including interactive
spec-all:
	crystal spec

# Run provider-specific tests
spec-provider:
	crystal spec --tag provider

# Record HTTP fixtures for provider tests
spec-provider-record:
	HTTP_RECORD=1 crystal spec --tag provider

# Run interactive tests (requires real terminal)
spec-interactive:
	WITH_TERMINAL=1 crystal spec --tag interactive

# Format all Crystal files
format:
	crystal tool format

# Generate documentation
docs:
	crystal docs

# Clean temporary files, logs, and build artifacts
clean:
	rm -rf temp/*
	rm -rf log/*
	rm -rf .crystal-cache
	rm -f *.dwarf
	@echo "Cleaned temp/, log/, .crystal-cache/, and *.dwarf files"

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
	@echo "  install            - Install dependencies"
	@echo "  spec               - Run tests (excluding interactive)"
	@echo "  spec-all           - Run all tests"
	@echo "  spec-interactive   - Run interactive tests"
	@echo "  format             - Format Crystal files"
	@echo "  docs               - Generate documentation"
	@echo "  clean              - Clean temp/, log/, cache, and artifacts"
	@echo "  benchmark          - Run performance benchmarks"
	@echo "  run-example        - Run an example (EXAMPLE=name)"
	@echo "  help               - Show this help"

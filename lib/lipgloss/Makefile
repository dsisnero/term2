.PHONY: build install spec spec-all spec-provider spec-provider-record spec-interactive clean format docs build-examples update_lrama update_racc update_submodules samples-crystal-gen samples-crystal-build samples-crystal-run samples-crystal samples-ruby-gen samples-ruby-build samples-ruby-run samples-ruby samples-all run_benchmark

# Crystal cache for faster builds
export CRYSTAL_CACHE_DIR := $(PWD)/.crystal-cache
export BEADS_DIR ?= $(PWD)/.beads

# Build the library (check for errors)
build:
	shards build

install:
	GIT_CONFIG_GLOBAL=/dev/null shards install

update:
	GIT_CONFIG_GLOBAL=/dev/null shards update

# Run all tests (excluding interactive)
spec:
	crystal spec

# Run all tests including interactive
spec-all:
	crystal spec

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
	@echo "Cleaned temp/, log/, .crystal-cache/, *.dwarf"


# Help
help:
	@echo "Lipgloss - Crystal Terminal Styling Library"
	@echo ""
	@echo "Available targets:"
	@echo "  install            - Install dependencies"
	@echo "  update             - Update dependencies"
	@echo "  spec               - Run tests (excluding interactive)"
	@echo "  format             - Format Crystal files"
	@echo "  docs               - Generate documentation"
	@echo "  clean              - Clean temp/, log/, cache, and built examples"
	@echo "  help               - Show this help"

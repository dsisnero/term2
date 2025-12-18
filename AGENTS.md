# AGENTS.md - AI Coding Assistant Guide

## Table of Contents

- [Agent Behavior](#agent-behavior)
- [Commands Reference](#commands-reference)
- [Code Style Guidelines](#code-style-guidelines)
- [Testing Conventions](#testing-conventions)

## Agent Behavior

### Core Workflow Principles

- **Use the shared cache**: export `CRYSTAL_CACHE_DIR=$PWD/.crystal-cache` for every `crystal` invocation
- **Clean artifacts** with `make clean` before recording logs or re-running flaky specs

### File Safety Protocol

- **NEVER INVENT FILE PATHS** - Always verify file existence before reading
- **ALWAYS USE DISCOVERY TOOLS FIRST** - Use `dir.list` to explore directories before file access
- **Use `grep` for file discovery** - Search for files by name or content before reading
- **Handle missing files gracefully** - Report missing files clearly rather than causing errors

## Commands Reference

### Development Commands

- **Install deps**: `make install` (or `shards install`)
- **Build**: `make build`
- **Run tests (all)**: `crystal spec` (or `crystal spec --fail-fast -v` when debugging)
- **Provider-only specs**: `make spec-provider` (set provider env vars first)
- **Capture live HTTP fixtures**: `make spec-provider-record` (sets `HTTP_RECORD=1`)
- **Interactive specs**: `make spec-interactive` (requires `WITH_TERMINAL=1`)
- **Test single file**: `crystal spec spec/<path_to_file>`
- **Run examples**: `crystal run examples/<example_name>.cr`
- **Format code**: `crystal tool format`
- **Lint & auto-fix**: `ameba --fix`
- **Clean logs/temp**: `make clean`

### Language & Version

- **Language**: Crystal (>= 1.18.2)
- **Project Name**: Term2 - Crystal Terminal Library

## Code Style Guidelines

### Formatting Standards

- **Indentation**: 2-space indent
- **Line endings**: LF line endings, UTF-8 encoding
- **Trailing newline**: Always include trailing newline in files
- **Naming**: `snake_case` for methods/variables, `PascalCase` for classes/modules
- **Types**: Explicit type annotations for method parameters and return types

### Code Quality

- **Logging**: Use `Log.debug`, `Log.info` for diagnostic output
- **Require order**: External dependencies first, then internal requires in alphabetical order
- **Error handling**: Comprehensive error handling with clear messages
- **Documentation**: Clear comments for complex logic and public APIs

### API Conventions

- **Model-Update-View**: Follow the Elm architecture.
- **Cmd**: Use `Term2::Cmd` (alias for `Proc(Msg?)?`) for commands.
- **Cmds**: Use `Term2::Cmds` module for command constructors (e.g., `Cmds.batch`, `Cmds.tick`).
- **Update Return**: `update` method must return `{Model, Cmd}`.
- **Messages**: Use `Term2::Msg` (alias for `Term2::Message`) for messages.

## Testing Conventions

### Spec Placement and Coverage

- All tests must live under the `spec/` directory
- Every new or modified source file under `src/` must have corresponding specs
- Temporary test files: `spec/<name_of_test>_temp.cr`

### Library Testing Requirements

- Cover all public API methods and terminal interactions
- Test concurrent behavior using cml channels and processes
- Verify terminal output, input handling, and UI components
- Follow existing spec structure in `spec/`

### Test Performance

- Prefer fast, deterministic tests
- Gate interactive terminal or live HTTP tests behind env flags
- Mark interactive tests as `pending` by default

### Environment Variables

- `TERM2_DEBUG` - enable debug logging for terminal interactions
- `TERM2_TEST_TTY` - use real TTY for interactive tests
- Optional logging: `TERM2_LOG_FILE=$PWD/temp/term2_debug.log`

### Debugging Tips

**Enable Detailed Logging:**

```bash
# Example with debug logging
TERM2_DEBUG=1 crystal run examples/simple.cr
```

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds

# AGENTS.md - AI Coding Assistant Guide

## Table of Contents

- [Agent Behavior](#agent-behavior)
- [Commands Reference](#commands-reference)
- [Code Style Guidelines](#code-style-guidelines)
- [Testing Conventions](#testing-conventions)
- [Tool Usage Guidelines](#tool-usage-guidelines)
- [Security Considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)

## Agent Behavior

### Core Workflow Principles

- **Always update plan.md** when completing phases or major features
- **Mark items complete** in plan.md and every plans/**/<name>  `[x]` when done
- **Update completion docs** when finishing phases (create PHASE_X_COMPLETION.md files)
- **Add specs for code changes** - add specs to test each code change in spec directory only
- **Scratch work and temp scripts go under `temp/`** - do not drop throwaway files in repo root
- **Run tests** after changes: `make spec-all`
- **Check build** after changes: `shards build` (or `make build`)
- **Use the shared cache**: export `CRYSTAL_CACHE_DIR=$PWD/.crystal-cache` for every `crystal` invocation
- **Clean artifacts** with `make clean` before recording logs or re-running flaky specs
- **Track progress** using plan.md as the source of truth

### File Safety Protocol

- **NEVER INVENT FILE PATHS** - Always verify file existence before reading
- **ALWAYS USE DISCOVERY TOOLS FIRST** - Use `dir.list` to explore directories before file access
- **Use `grep` for file discovery** - Search for files by name or content before reading
- **Handle missing files gracefully** - Report missing files clearly rather than causing errors

## Commands Reference

### Development Commands

- **Install deps**: `make install` (or `shards install`)
- **Build**: `make build`
- **Run tests (all)**: `make spec-all`
- **Provider-only specs**: `make spec-provider` (set provider env vars first)
- **Capture live HTTP fixtures**: `make spec-provider-record` (sets `HTTP_RECORD=1`)
- **Interactive specs**: `make spec-interactive` (requires `WITH_TERMINAL=1`)
- **Test single file**: `crystal spec spec/<path_to_file>`
- **Run examples**: `crystal run examples/<example_name>.cr`
- **Format code**: `crystal tool format`
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

## Tool Usage Guidelines

### File Operations

- **Read files**: Use `file.read` with verified paths
- **Write files**: Use `file.patch` for modifications
- **Directory listing**: Always use `dir.list` before file operations
- **File discovery**: Use `grep` to search for files by content

### Memory Management

- **Store memories**: Use `memory.write` for persistent storage
- **Retrieve memories**: Use `memory.read`, `memory.list`, or `memory.search`
- **Plan management**: Use `plan.create` and `plan.update` only

### Shell Operations

- **Run commands**: Use `shell.run` with explicit `cmd`/`args`
- **Avoid raw shell**: Never use improvised multi-line shell sessions
- **Safe commands**: Only use commands listed in `safe_commands`

## Running Live Provider Tests

### Environment Variables

- `TERM2_DEBUG` - enable debug logging for terminal interactions
- `TERM2_TEST_TTY` - use real TTY for interactive tests
- Optional logging: `TERM2_LOG_FILE=$PWD/temp/term2_debug.log`

### Tag Strategy

- **Run everything**: `crystal spec --tag "~interactive"`
- **Skip interactive tests**: append `--tag "~interactive"`
- **Run only interactive tests**: `crystal spec --tag interactive`
- **Run with TTY tests**: `TERM2_TEST_TTY=1 crystal spec`

### Notes

- Interactive tests require a real terminal and may be marked as pending
- TTY tests require `TERM2_TEST_TTY=1` environment variable

## Security Considerations

### Code Security

- Validate all inputs and sanitize user data
- Use parameterized queries for database operations
- Implement proper authentication and authorization
- Avoid hardcoded secrets and API keys

### File Safety

- Verify file paths before operations
- Sanitize file names and paths
- Implement proper error handling for file operations
- Log security-relevant events

### Network Security

- Use HTTPS for external API calls
- Validate SSL certificates
- Implement rate limiting for API calls
- Sanitize log output to avoid leaking sensitive data

## Troubleshooting

### Common Issues

**Build Failures:**

```bash
# Clear cache and rebuild
shards install
shards build
```

**Test Failures:**

```bash
# Run specific test with tracing
crystal spec spec/path/to/test.cr --error-trace
```

**Interactive Test Issues:**

```bash
# Check environment variables
echo $TERM2_TEST_TTY
# Enable debug logging
TERM2_DEBUG=1 crystal spec --tag interactive
```

**File Path Errors:**

- Always use `dir.list` to discover files before reading
- Never assume file paths exist
- Use `grep` to search for files by content

### Debugging Tips

**Enable Detailed Logging:**

```bash
# Example with debug logging
TERM2_DEBUG=1 crystal run examples/simple.cr
```

**Memory Issues:**

```bash
# Check memory usage
memory.list
# Search memories
memory.search "keyword"
```

**Performance Profiling:**

```bash
# Build with debug info
shards build --debug
```

## Recent Major Accomplishments

- [Add recent accomplishments here as they occur]

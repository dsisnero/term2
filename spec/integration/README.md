# Integration Tests

This directory contains integration tests that verify the patch tool works with real AI providers.

## Setup

### Environment Variables

Integration tests require API keys for AI providers. These should be managed securely using SOPS:

1. Create a `.env` file with your API keys:

```bash
OPENAI_API_KEY=your_openai_key
ANTHROPIC_API_KEY=your_anthropic_key
GROQ_API_KEY=your_groq_key
```

1. Encrypt the file:

```bash
sops --encrypt --output .env.enc .env
```

1. Decrypt when running tests:

```bash
sops --decrypt --output .env .env.enc
```

### Running Tests

Run all integration tests:

```bash
crystal spec spec/integration/
```

Run specific patch tool integration tests:

```bash
crystal spec spec/integration/patch_tool_integration_spec.cr
```

Run tests with a specific provider:

```bash
OPENAI_API_KEY=your_key crystal spec spec/integration/patch_tool_integration_spec.cr
```

## Test Structure

### Patch Tool Integration Tests

These tests verify that:

- Natural language commands generate proper unified diff format responses
- Class rename operations work correctly
- API addition commands generate valid code
- Multiple file modifications are handled properly
- Error cases are handled gracefully

### Provider Tests

Tests marked with `tags: ["provider"]` require actual API keys and will:

- Connect to real AI providers
- Generate actual patches based on natural language
- Validate the response format and content

## Test Data

Tests create temporary files in `tmp/patch_tool_test/` directory that are cleaned up after each test.

## Security Notes

- API keys are never committed to the repository
- All sensitive data is encrypted using SOPS
- Tests validate that no hardcoded secrets are present
- Environment variables are loaded securely
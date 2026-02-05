# Crystal Port of Similar Diff Library

## Overview

Port the Rust `similar` crate (version 2.7.0) to Crystal, aiming for full feature parity with minimal external dependencies. The port will include all core diffing algorithms (Myers, Patience, LCS), text diffing utilities, unified diff generation, inline change detection, Unicode support (grapheme and word segmentation), byte slice diffing, serialization support, and deadline/timeout functionality.

## Architecture Mapping

### Rust Concepts to Crystal Equivalents

| Rust Concept | Crystal Equivalent | Notes |
|--------------|-------------------|-------|
| Traits (`DiffHook`, `DiffableStr`) | Modules / abstract classes | Use abstract classes with abstract methods, or modules with macro-generated type checks. |
| Generics (`T: DiffableStr + ?Sized`) | Generic type parameters | Crystal supports generic type parameters in classes and modules. Use `T` constrained by module inclusion. |
| Lifetimes (`'a`, `'bufs`) | Reference types / generic type parameters | Crystal's type system doesn't have explicit lifetimes; rely on the garbage collector. For borrowed slices, use generic type parameters to capture the underlying data lifetime (e.g., `struct TextDiff(T)` where `T` is the slice type). |
| Enum (`Algorithm`, `ChangeTag`, `DiffOp`) | Enum (Crystal 1.0+) | Use Crystal's enum feature. |
| Feature flags (`#[cfg(feature = \"unicode\")]`) | Conditional compilation (`{% if flag?(:unicode) %}`) | Since the user wants all features included, we may not need feature flags. However, we can keep them as compile-time flags for optional dependencies. |
| Optional dependencies (`unicode-segmentation`, `bstr`, `serde`) | Minimal dependencies; implement needed functionality inline or rely on Crystal stdlib. | Unicode segmentation may require custom implementation or using `String#each_grapheme` from `crystal-unicode`. The user prefers minimal dependencies, so we may implement basic grapheme clustering using Unicode rules (UAX #29) or fall back to character (codepoint) diffing. |
| `Instant` / deadlines | `Time.monotonic` | Use `Time.monotonic` for deadlines; note that `monotonic` returns `Time::Span`. |
| `serde` serialization | `JSON.mapping` / `YAML.mapping` | Provide `to_json` and `from_json` for enums and structs that need serialization. |

### Core Types

- `Algorithm` (Myers, Patience, LCS)
- `ChangeTag` (Equal, Delete, Insert)
- `DiffTag` (Equal, Delete, Insert, Replace)
- `DiffOp` (Equal, Delete, Insert, Replace) – struct-like enum variants with fields.
- `Change` – generic struct with tag, old_index, new_index, value.
- `TextDiff` – main text diffing struct with old/new slices, ops, newline_terminated flag.
- `DiffHook` – abstract class for low-level diff algorithm callbacks.
- `DiffableStr` – abstract class for string-like types (str, bytes, etc.).

### Module Structure

Mirror the Rust crate's module structure:

```
src/
  similar.cr (main module, re-exports)
  algorithms/
    mod.cr (diff, diff_deadline, DiffHook, Capture, Compact, Replace)
    myers.cr
    patience.cr
    lcs.cr
    utils.cr (IdentifyDistinct, etc.)
  iter.cr (ChangesIter, AllChangesIter)
  types.cr (Algorithm, ChangeTag, DiffTag, DiffOp, Change)
  common.cr (capture_diff*, get_diff_ratio, group_diff_ops)
  text/
    mod.cr (TextDiff, TextDiffConfig, DiffableStr, DiffableStrRef)
    abstraction.cr (DiffableStr implementation for String, Bytes, etc.)
    inline.cr (InlineChange, iter_inline_changes)
    utils.cr (tokenize_lines, tokenize_words, tokenize_chars, tokenize_graphemes, tokenize_unicode_words)
  udiff.cr (UnifiedDiff, UnifiedDiffHunk, UnifiedHunkHeader)
  utils.cr (TextDiffRemapper, diff_slices, diff_chars, diff_words, diff_lines, etc.)
  deadline_support.cr (Instant, duration_to_deadline)
```

## Dependencies and Feature Decisions

### Unicode Support

The Rust crate uses `unicode-segmentation` for grapheme clustering and Unicode word boundaries. Options:

1. Implement UAX #29 segmentation ourselves (complex).
2. Use `crystal-unicode` shard (adds dependency).
3. Fall back to character (codepoint) diffing for graphemes, and simple whitespace-based word splitting for Unicode words.

Given the user's preference for minimal dependencies, we will implement:

- Grapheme clustering: Use a simple algorithm based on Unicode grapheme cluster boundaries (maybe using property tables from Unicode). Could be limited but work for most common cases.
- Unicode word boundaries: Use Unicode character categories (letter, number, punctuation) from Crystal's `Char#letter?`, `Char#number?`, etc. (Crystal's `Char` provides some categorization). We'll implement a basic tokenizer that splits on changes of character category.

If this proves too complex, we can later add `crystal-unicode` as an optional dependency.

### Bytes Support

Implement `DiffableStr` for `Bytes` (slice of UInt8). Crystal's `Bytes` provides indexing and slicing.

### Inline Feature

Implement second-level diff on adjacent replaced lines using the same diff algorithms. Use a configurable deadline (default 500ms). Use character or word-level diffing for inline changes.

### Serialization

Implement `JSON.mapping` for `ChangeTag`, `DiffTag`, `DiffOp`, `Change`. Provide `to_json` and `from_json` methods. Since enums in Crystal can be serialized by name, we can map accordingly.

### Deadline Support

Use `Time.monotonic` to track deadlines. The algorithms need to check deadlines periodically; we'll integrate checks in loops.

## Testing Strategy

- Convert Rust crate's tests to Crystal spec.
- Use existing test data from Rust crate (snapshots).
- Ensure edge cases: empty sequences, large inputs, Unicode, missing newlines.
- Run tests with `crystal spec`.

We'll need to copy the test snapshots from Rust crate (insta snapshots) into spec fixtures.

## Implementation Steps

### Phase 1: Core Types and Algorithms

1. Define enums `Algorithm`, `ChangeTag`, `DiffTag` in `src/types.cr`.
2. Define `DiffOp` enum with struct variants and methods (`tag`, `old_range`, `new_range`, `iter_changes`, `iter_slices`, `apply_to_hook`).
3. Define `Change` struct with generic type parameter.
4. Implement `DiffHook` abstract class with methods `equal`, `delete`, `insert`, `replace`, `finish`.
5. Implement `Capture`, `Compact`, `Replace` hook wrappers (algorithms/capture.cr, compact.cr, replace.cr).
6. Implement `IdentifyDistinct` utility (algorithms/utils.cr).
7. Implement Myers diff algorithm (algorithms/myers.cr) with deadline support.
8. Implement Patience diff algorithm (algorithms/patience.cr).
9. Implement LCS diff algorithm (algorithms/lcs.cr).
10. Implement `diff`, `diff_deadline`, `diff_slices`, `diff_slices_deadline` in algorithms/mod.cr.
11. Implement `capture_diff`, `capture_diff_slices`, `get_diff_ratio`, `group_diff_ops` in common.cr.
12. Write specs for core diffing (compare with Rust test results).

### Phase 2: Iteration and Text Abstraction

1. Implement `ChangesIter` and `AllChangesIter` in iter.cr.
2. Define `DiffableStr` abstract class with methods: `len`, `slice`, `as_bytes`, `to_string_lossy`, `as_str?`, `ends_with_newline`, `tokenize_lines`, `tokenize_words`, `tokenize_chars`, `tokenize_graphemes`, `tokenize_unicode_words`.
3. Provide implementations for `String` and `Bytes` (text/abstraction.cr).
4. Implement tokenizers (text/utils.cr):
   - `tokenize_lines`: split on `\n`, keep newline character.
   - `tokenize_words`: split on whitespace boundaries (ASCII).
   - `tokenize_chars`: each character as a slice (codepoint).
   - `tokenize_graphemes`: grapheme cluster segmentation (basic implementation).
   - `tokenize_unicode_words`: Unicode word boundaries (basic implementation).
5. Write specs for tokenizers.

### Phase 3: Text Diffing

1. Implement `TextDiffConfig` and `TextDiff` structs (text/mod.cr).
2. Implement `diff_lines`, `diff_words`, `diff_chars`, `diff_unicode_words`, `diff_graphemes`, `diff_slices` methods.
3. Implement `iter_changes`, `iter_all_changes`, `ratio`, `grouped_ops`, `unified_diff`.
4. Write specs for text diffing (use examples from Rust tests).

### Phase 4: Unified Diff

1. Implement `UnifiedDiff`, `UnifiedDiffHunk`, `UnifiedHunkHeader` (udiff.cr).
2. Implement `to_writer` and `Display` formatting.
3. Write specs for unified diff output.

### Phase 5: Utilities and Remapping

1. Implement `TextDiffRemapper` (utils.cr).
2. Implement convenience functions `diff_slices`, `diff_chars`, `diff_words`, `diff_lines`, `diff_unicode_words`, `diff_graphemes`.
3. Write specs.

### Phase 6: Inline Changes

1. Implement `InlineChange` struct (text/inline.cr).
2. Implement `iter_inline_changes` and `iter_inline_changes_deadline`.
3. Write specs.

### Phase 7: Serialization

1. Add `JSON.mapping` to enums and structs (maybe via `@[JSON::Serializable]` annotation).
2. Write specs for serialization roundtrip.

### Phase 8: Deadline Support

1. Implement `Instant` wrapper around `Time.monotonic` (deadline_support.cr).
2. Integrate deadline checks into algorithms.
3. Write specs for timeout behavior.

### Phase 9: Integration and Polish

1. Update shard.yml with version, authors, license.
2. Ensure documentation comments (crystal docs).
3. Run full test suite, fix any issues.
4. Benchmark performance against Rust crate (optional).
5. Create examples (mirror Rust examples).

## Potential Challenges

1. **Lifetime management**: Crystal's GC should handle lifetimes, but we must ensure slices don't outlive underlying data. Use generic type parameters to tie lifetimes.
2. **Unicode segmentation**: Implementing correct grapheme and word boundaries is nontrivial. We may need to compromise on accuracy.
3. **Performance**: Diff algorithms are performance-sensitive. Crystal's speed is good but we need to optimize hot loops (avoid allocations, use indices).
4. **Deadline integration**: Algorithms need to check deadlines frequently without heavy overhead. Use coarse-grained checks.
5. **Serialization**: Crystal's JSON mapping may not match Rust's serde output exactly. We can aim for compatibility but not required.

## Timeline

Estimate: 2-3 weeks of focused work, assuming ~20-30 hours.

## Next Steps

1. Begin Phase 1 implementation.
2. After each phase, run tests and ensure correctness.
3. Iterate based on user feedback.

---

*Last updated: 2026-01-30*
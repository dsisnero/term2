# Lipgloss Examples Porting Progress

This directory contains ports of lipgloss examples to term2.

## Completed Examples

### List Examples

- [x] `list/simple` - Simple list with Roman numeral sublist
- [x] `list/bullet` - Bullet point lists
- [x] `list/dash` - Dash lists
- [x] `list/asterisk` - Asterisk lists
- [x] `list/alphabet` - Alphabetical lists
- [x] `list/arabic` - Arabic numeral lists
- [x] `list/roman` - Roman numeral lists
- [x] `list/none` - No enumeration

## In Progress Examples

- None

## Pending Examples

### Examples Found in lipgloss/examples Directory

- [ ] `layout/` - Layout examples (simple.go)
- [ ] `table/` - Table examples (pokemon.go)
- [ ] `tree/` - Tree examples (simple.go)
- [ ] `ssh/` - SSH integration example (main.go)

### Other Examples (mentioned in documentation)

- [ ] `border` - Border styles
- [ ] `color` - Color examples
- [ ] `margin` - Margin examples
- [ ] `padding` - Padding examples
- [ ] `style` - Style combinations
- [ ] `text` - Text styling

## Notes

1. **Architecture Difference**: term2's `List` component is an interactive UI component with pagination and selection, while lipgloss's list is a simple text formatter. For porting, we create simple text formatting functions.

2. **Implementation Approach**: For list examples, we create simple formatting functions that mimic lipgloss behavior rather than using term2's interactive List component.

3. **Directory Structure**: Each example should maintain the same directory structure as the original lipgloss examples.

4. **TODO Comments**: Use `# TODO: Port from lipgloss` comments in files to track what needs to be implemented.

## Porting Strategy

Based on examination of lipgloss examples, here's the recommended approach:

1. **Layout Examples**: Simple layout examples using `lipgloss.Place` and positioning
2. **Table Examples**: Pokemon table example showing table formatting
3. **Tree Examples**: Simple tree structure rendering
4. **SSH Examples**: Advanced example showing SSH server integration with custom renderers
5. **Style Examples**: Basic style combinations (border, color, margin, padding, text)

## Next Steps

1. Create directory structure for remaining examples
2. Port layout examples first (simplest)
3. Port table examples
4. Port tree examples
5. Port SSH examples (most complex)
6. Create basic style examples for border, color, margin, padding, text
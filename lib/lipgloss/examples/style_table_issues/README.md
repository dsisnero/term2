# StyleTable Issue Repros

Run these from repo root:

- `crystal run examples/style_table_issues/lnd_fixed_width_padding.cr`
- `crystal run examples/style_table_issues/rqv_multilingual_wrap.cr`

These examples reproduce current Go-parity gaps tracked in:

- `lipgloss-lnd` (fixed-width + padding height semantics)
- `lipgloss-rqv` (multilingual wrap width parity)

require "spec"
require "golden"
require "../src/term2"
require "lipgloss"
Lipgloss::StyleRenderer.default.color_profile = Lipgloss::ColorProfile::ANSI
require "./support/teatest"
require "./support/view_helpers"
require "./support/uv_helpers"

Golden.init
Golden.dir = Golden.spec_test_data_dir || "spec/testdata"

# Environment variables should be loaded via sops or directly in the environment
# before running the tests

require "spec"
require "golden"
require "../src/term2"
require "./support/teatest"
require "./support/view_helpers"

Golden.init

# Environment variables should be loaded via sops or directly in the environment
# before running the tests

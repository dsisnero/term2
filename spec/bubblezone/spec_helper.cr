# spec/bubblezone/spec_helper.cr
# Bubblezone-specific spec helper

require "../../spec/spec_helper"
require "./support/bubblezone_helpers_spec"

# Setup for bubblezone tests
Spec.before_each do
  Term2::Zone.reset
end

Spec.after_each do
  Term2::Zone.reset
end

Spec.before_suite do
  # Ensure zone system is initialized
  Term2::Zone.reset
end

Spec.after_suite do
  # Clean up after all tests
  Term2::Zone.reset
end

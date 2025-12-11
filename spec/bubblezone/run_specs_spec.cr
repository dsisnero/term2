#!/usr/bin/env crystal
# spec/bubblezone/run_specs.cr
# Runner for bubblezone specs

require "spec"

# Load all bubblezone specs
require "./spec_helper"
require "./unit/zoneinfo_spec"
require "./unit/manager_spec"
require "./integration/complex_scenarios_spec"
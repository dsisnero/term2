# This module implements diffing utilities.  It attempts to provide an abstraction
# interface over different types of diffing algorithms.  The design of the library is
# inspired by pijul's diff library by Pierre-Étienne Meunier and also inherits the
# patience diff algorithm from there.
#
# The API of the crate is split into high and low level functionality.  Most
# of what you probably want to use is available top level.  Additionally the
# following sub modules exist:
#
# * `Similar::Algorithms`: This implements the different types of diffing algorithms.
#   It provides both low level access to the algorithms with the minimal
#   trait bounds necessary, as well as a generic interface.
# * `Similar::Udiff`: Unified diff functionality.
# * `Similar::Utils`: utilities for common diff related operations.  This module
#   provides additional diffing functions for working with text diffs.

# Load core types
require "./types"

# Load algorithms
require "./algorithms/mod"

# Load common utilities
require "./common"

# Load deadline support
require "./deadline_support"

# Load iterators
require "./iter"

# Load text diffing
require "./text/mod"

# Load utilities
require "./utils"

module Similar
  VERSION = "0.1.0"
end

# frozen_string_literal: true

module Reviewer
  # Bundles the shared runtime dependencies that flow through the review/format lifecycle.
  # Passed from Session → Batch → Runner → Command so that no class needs to reach
  # into module-level globals for arguments, output, or history.
  #
  # @!attribute [rw] arguments
  #   @return [Arguments] the parsed command-line arguments
  # @!attribute [rw] output
  #   @return [Output] the output channel for displaying content
  # @!attribute [rw] history
  #   @return [History] the YAML store for timing data and prepare timestamps
  # Bundles the shared runtime dependencies that flow through the review/format lifecycle.
  # All parameters are required — no global defaults.
  Context = Struct.new(:arguments, :output, :history, keyword_init: true)
end

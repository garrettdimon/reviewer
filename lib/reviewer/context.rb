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
  Context = Struct.new(:arguments, :output, :history, keyword_init: true) do
    # Creates a new Context, defaulting each dependency to the current Reviewer globals.
    # Entry points (Session, tests) call Context.new; downstream classes receive it as a required parameter.
    #
    # @param arguments [Arguments] defaults to Reviewer.arguments
    # @param output [Output] defaults to Reviewer.output
    # @param history [History] defaults to Reviewer.history
    def initialize(arguments: Reviewer.arguments, output: Reviewer.output, history: Reviewer.history)
      super
    end
  end
end

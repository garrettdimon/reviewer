# frozen_string_literal: true

module Reviewer
  # Simple interactive prompt for yes/no questions.
  # Wraps input/output streams for testability.
  class Prompt
    attr_reader :input, :output

    # Creates an interactive prompt for yes/no questions
    # @param input [IO] the input stream (defaults to $stdin)
    # @param output [IO] the output stream (defaults to $stdout)
    #
    # @return [Prompt]
    def initialize(input: $stdin, output: $stdout)
      @input = input
      @output = output
    end

    # Asks a yes/no question and returns the boolean result.
    # Returns false in non-interactive contexts (CI, pipes).
    #
    # @param message [String] the question to display
    # @return [Boolean] true if the user answered yes
    def yes?(message)
      return false unless interactive?

      @output.print "#{message} (y/n) "
      response = @input.gets&.strip&.downcase
      response&.start_with?('y') || false
    end

    private

    def interactive?
      @input.respond_to?(:tty?) && @input.tty?
    end
  end
end

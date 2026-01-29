# frozen_string_literal: true

module Reviewer
  class Arguments
    # Handles interpreting all 'leftover' arguments and translating them to file-related,
    # tag-related, or tool-related arguments
    #
    # @!attribute provided
    #   @return [Array<String>] the keywords extracted from the command-line arguments
    class Keywords
      RESERVED = %w[staged unstaged modified untracked failed].freeze

      attr_accessor :provided

      alias raw provided

      # Generates an instance of parsed keywords from the provided arguments
      # @param *provided [Array<String>] the leftover (non-flag) arguments from the command line
      #
      # @return [self]
      def initialize(*provided)
        @provided = Array(provided.flatten)
      end

      # Proves the full list of raw keyword arguments explicitly passed via command-line as an array
      #
      # @return [Array] full collection of the provided keyword arguments as a string
      def to_a = provided

      # Provides the full list of raw keyword arguments explicitly passed via command-line as a
      #   comma-separated string
      #
      # @return [String] comma-separated list of the file arguments as a string
      def to_s = to_a.join(',')

      # Summary of the state of keyword arguments based on how Reviewer parsed them
      #
      # @return [Hash] represents the summary of the keyword values parsed from the command-line and
      #   grouped based on how they were parsed
      def to_h
        {
          provided: provided,
          recognized: recognized,
          unrecognized: unrecognized,
          reserved: reserved,
          for_tags: for_tags,
          for_tool_names: for_tool_names
        }
      end
      alias inspect to_h

      # Whether the `failed` keyword was provided
      #
      # @return [Boolean] true if the `failed` keyword is present
      def failed? = provided.include?('failed')

      # Extracts reserved keywords from the provided arguments
      #
      # @return [Array<String>] intersection of provided arguments and reserved keywords
      def reserved = intersection_with(RESERVED)

      # Extracts keywords that match configured tags for enabled tools
      #
      # @return [Array<String>] intersection of provided arguments and configured tags for tools
      def for_tags = intersection_with(configured_tags)

      # Extracts keywords that match configured tool keys
      #
      # @return [Array<String>] intersection of provided arguments and configured tool names
      def for_tool_names = intersection_with(configured_tool_names)

      # Extracts keywords that match any possible recognized keyword values
      #
      # @return [Array<String>] intersection of provided arguments and recognizable keywords
      def recognized = intersection_with(possible)

      # Extracts keywords that don't match any possible recognized keyword values
      #
      # @return [Array<String>] leftover keywords that weren't recognized
      def unrecognized = (provided - recognized).uniq.sort

      # Provides the complete list of all recognized keywords based on configuration
      #
      # @return [Array<String>] all keywords that Reviewer can recognized
      def possible = (RESERVED + configured_tags + configured_tool_names).uniq.sort

      # Provides the complete list of all configured tags for enabled tools
      #
      # @return [Array<String>] all unique configured tags
      def configured_tags = tools.enabled.map(&:tags).flatten.uniq.sort

      # Provides the complete list of all configured tool names for enabled tools
      #
      # @return [Array<String>] all unique configured tools
      def configured_tool_names
        # We explicitly don't sort the tool names list because Reviewer uses the configuration order
        # to determine the execution order. So not sorting maintains the predicted order it will run
        # in and leaves the option to sort to the consuming code if needed
        tools.all.map { |tool| tool.key.to_s }
      end

      private

      # Provides a collection of enabled Tools for convenient access
      #
      # @return [Array<Reviewer::Tool>] collection of all currently enabled tools
      def tools = @tools ||= Reviewer.tools

      # Syntactic sugar for finding intersections with valid keywords
      # @param values [Array<String>] the collection to use for finding intersecting values
      #
      # @return [Array<String>] the list of intersecting values
      def intersection_with(values) = (values & provided).uniq.sort
    end
  end
end

# frozen_string_literal: true

require_relative 'keywords/git'

module Reviewer
  class Arguments
    # Handles interpreting all 'leftover' arguments and translating them to file-related,
    # tag-related, or tool-related arguments
    class Keywords
      RESERVED = %w[staged].freeze

      attr_accessor :provided

      alias raw provided

      def initialize(*provided)
        @provided = Array(provided.flatten)
      end

      def to_a
        provided
      end

      def to_s
        to_a.join(',')
      end

      def inspect
        {
          provided: provided,
          recognized: recognized,
          unrecognized: unrecognized,
          reserved: reserved,
          for_tags: for_tags,
          for_tool_names: for_tool_names
        }
      end

      # Extracts reserved keywords from the provided arguments
      #
      # @return [Array<String>] intersection of provided arguments and reserved keywords
      def reserved
        intersection_with RESERVED
      end

      # Extracts keywords that match configured tags for enabled tools
      #
      # @return [Array<String>] intersection of provided arguments and configured tags for tools
      def for_tags
        intersection_with configured_tags
      end

      # Extracts keywords that match configured tool keys
      #
      # @return [Array<String>] intersection of provided arguments and configured tool names
      def for_tool_names
        intersection_with configured_tool_names
      end

      # Extracts keywords that match any possible recognized keyword values
      #
      # @return [Array<String>] intersection of provided arguments and recognizable keywords
      def recognized
        intersection_with possible
      end

      # Extracts keywords that don't match any possible recognized keyword values
      #
      # @return [Array<String>] leftover keywords that weren't recognized
      def unrecognized
        (provided - recognized).uniq.sort
      end

      # Provides the complete list of all recognized keywords based on configuration
      #
      # @return [Array<String>] all keywords that Reviewer can recognized
      def possible
        (RESERVED + configured_tags + configured_tool_names).uniq.sort
      end

      # Provides the complete list of all configured tags for enabled tools
      #
      # @return [Array<String>] all unique configured tags
      def configured_tags
        enabled_tools.map(&:tags).flatten.uniq.sort
      end

      # Provides the complete list of all configured tool names for enabled tools
      #
      # @return [Array<String>] all unique configured and enabled tools
      def configured_tool_names
        # We explicitly don't sort the tool names list because Reviewer uses the configuration order
        # to determine the execution order. So not sorting maintains the predicted order it will run
        # in and leaves the option to sort to the consuming code if needed
        enabled_tools.map { |tool| tool.key.to_s }.flatten.uniq
      end

      private

      # Provides a collection of enabled Tools for convenient access
      #
      # @return [Array<Reviewer::Tool>] collection of all currently enabled tools
      def enabled_tools
        @enabled_tools ||= Reviewer.tools.enabled
      end

      # Syntactic sugar for finding intersections with valid keywords
      # @param values [Array<String>] the collection to use for finding intersecting values
      #
      # @return [Array<String>] the list of intersecting values
      def intersection_with(values)
        values.intersection(provided).uniq.sort
      end
    end
  end
end

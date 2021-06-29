# frozen_string_literal: true

require_relative 'keywords/git'

module Reviewer
  class Arguments
    # Handles interpreting all 'leftover' arguments and translating them
    # to file-related, tag-related, or tool-related arguments
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

      def reserved
        intersection_with RESERVED
      end

      def for_tags
        intersection_with configured_tags
      end

      def for_tool_names
        intersection_with configured_tool_names
      end

      def recognized
        intersection_with possible
      end

      def unrecognized
        (provided - recognized).uniq.sort
      end

      def possible
        (RESERVED + configured_tags + configured_tool_names).uniq.sort
      end

      def configured_tags
        Reviewer.configuration.tools.values.map do |tool|
          tool.fetch(:tags) { [] }
        end.flatten.uniq
      end

      def configured_tool_names
        Reviewer.configuration.tools.keys.flatten.uniq
      end

      private

      def intersection_with(values)
        values.intersection(provided).uniq.sort
      end
    end
  end
end

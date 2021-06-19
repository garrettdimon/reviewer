# frozen_string_literal: true

require_relative 'keywords/git'

module Reviewer
  class Arguments
    # Handles interpreting all 'leftover' arguments and translating them
    # to file-related, tag-related, or tool-related arguments
    class Keywords
      RESERVED = %w[staged].freeze

      attr_accessor :provided

      def initialize(*provided)
        @provided = provided
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
          for_commands: for_commands
        }
      end

      def reserved
        provided.intersection(RESERVED).uniq.sort
      end

      def recognized
        provided.intersection(possible).uniq.sort
      end

      def unrecognized
        (provided - recognized).uniq.sort
      end

      def for_tags
        provided.intersection(configured_tags).uniq.sort
      end

      def for_commands
        provided.intersection(configured_commands).uniq.sort
      end

      def possible
        (RESERVED + configured_tags + configured_commands).uniq.sort
      end

      def conflicts
        []
      end

      def conflicts?
        conflicts.any?
      end

      def configured_tags
        configuration.tools.map(&:tags).flatten
      end

      def configured_commands
        configuration.tools.keys.flatten
      end
    end
  end
end

# frozen_string_literal: true

module Reviewer
  class Arguments
    # Handles the logic of translating tag arguments
    class Tags
      # @!attribute provided
      #   @return [Array<String>] tags explicitly provided via -t or --tags flag
      # @!attribute keywords
      #   @return [Array<String>] tags derived from keyword arguments
      attr_reader :provided, :keywords

      alias raw provided

      # Generates an instace of parsed tags from the provided arguments by merging tag arguments
      #   that were provided via either flags or keywords
      # @param provided: Reviewer.arguments.tags.raw [Array<String>] tag arguments provided
      #   directly via the -t or --tags flag on the command line.
      # @param keywords: Reviewer.arguments.keywords [Array, String] keywords that can potentially
      #   be translated to a list of tags based on the tags used in the configuration file
      #
      # @example Using keywords: `rvw ruby` (assuming a 'ruby' tag is defined)
      #   Reviewer::Arguments::Tags.new.to_a # => ['ruby']
      # @example Using the `-t` flag: `rvw -t ruby`
      #   Reviewer::Arguments::Tags.new.to_a # => ['ruby']
      # @example Using the `--tags` flag: `rvw -t ruby,css`
      #   Reviewer::Arguments::Tags.new.to_a # => ['css', 'ruby']
      #
      # @return [self]
      def initialize(provided: Reviewer.arguments.tags.raw, keywords: Reviewer.arguments.keywords.for_tags)
        @provided = Array(provided)
        @keywords = Array(keywords)
      end

      # Provides the full list of tags values derived from the command-line arguments
      #
      # @return [Array<String>] full collection of the tag arguments as a string
      def to_a = tag_list

      # Provides the full list of tag values derived from the command-line arguments
      #
      # @return [String] comma-separated string of the derived tag values
      def to_s = to_a.join(',')

      # Summary of the state of the tag arguments
      #
      # @return [Hash] represents the summary of the tag values parsed from the command-line
      def to_h
        {
          provided: provided.sort,
          from_keywords: keywords.sort
        }
      end
      alias inspect to_h

      private

      # Combines the sorted list of unique tags by merging the explicitly-provided tag arguments
      #   as well as those that were recognized from any relevant keyword arguments.
      #
      # @return [Array] full list of tags passed via command-line including those matching keyword
      #   arguments
      def tag_list
        @tag_list ||= [
          *provided,
          *keywords
        ].compact.sort.uniq
      end
    end
  end
end

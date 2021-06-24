# frozen_string_literal: true

module Reviewer
  class Arguments
    # Handles the logic of translating tag arguments
    class Tags
      attr_accessor :provided, :keywords

      def initialize(provided: Reviewer.arguments.tags, keywords: Reviewer.keywords.for_tags)
        @provided = Array(provided)
        @keywords = Array(keywords)
      end

      def to_a
        tag_list
      end

      def to_s
        to_a.join(',')
      end

      def inspect
        {
          provided: provided,
          from_keywords: from_keywords
        }
      end

      private

      def tag_list
        @tag_list ||= [
          *provided,
          *keywords
        ].sort.uniq
      end
    end
  end
end

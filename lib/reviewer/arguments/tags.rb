# frozen_string_literal: true

module Reviewer
  class Arguments
    # Handles the logic of translating tag arguments
    class Tags
      attr_accessor :provided

      def initialize(provided: nil, keywords: nil)
        @provided = provided || Reviewer.arguments.tags
        @keywords = keywords || Reviewer.arguments.keywords
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
          *from_keywords
        ].sort.uniq
      end

      def from_keywords
        return [] unless keywords.any?

        keywords.map do |keyword|
          send(keyword) if defined?(keyword)
        end.flatten.uniq
      end

      def staged
        # Use git for list of staged fields
        ::Reviewer::Arguments::Keywords::Git::Staged.new.list
      end
    end
  end
end

# frozen_string_literal: true

module Reviewer
  class Arguments
    # Generates the list of files to run the command against
    class Files
      attr_reader :provided, :keywords

      alias raw provided

      def initialize(provided: Reviewer.arguments.files.raw, keywords: Reviewer.arguments.keywords)
        @provided = Array(provided)
        @keywords = Array(keywords)
      end

      def to_a
        file_list
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

      def file_list
        @file_list ||= [
          *provided,
          *from_keywords
        ].compact.sort.uniq
      end

      def from_keywords
        return [] unless keywords.any?

        keywords.map do |keyword|
          keyword = keyword.to_sym
          send(keyword) if respond_to?(keyword)
        end.flatten.uniq
      end

      def staged
        # Use git for list of staged fields
        ::Reviewer::Arguments::Keywords::Git::Staged.list
      end
    end
  end
end

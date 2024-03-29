# frozen_string_literal: true

module Reviewer
  class Arguments
    # Generates a Ruby-friendly list (Array) of files to run the command against from the provided
    # command line arguments
    class Files
      attr_reader :provided, :keywords

      alias raw provided

      # Generates an instance of files from the provided arguments
      # @param provided: Reviewer.arguments.files.raw [Array, String] file arguments provided
      #   directly via the -f or --files flag on the command line.
      # @param keywords: Reviewer.arguments.keywords [Array, String] keywords that can potentially
      #   be translated to a list of files (ex. 'staged')
      #
      # @example Using the `-f` flag: `rvw -f ./file.rb`
      #   reviewer = Reviewer::Arguments::Files.new(provided: ['./file.rb'], keywords: [])
      #   reviewer.to_a # => ['./file.rb']
      # @example Using the `--files` flag: `rvw --files ./file.rb,./directory/file.rb
      #   reviewer = Reviewer::Arguments::Files.new(provided: ['./file.rb','./directory/file.rb'], keywords: [])
      #   reviewer.to_a # => ['./file.rb','./directory/file.rb']
      #
      # @return [self]
      def initialize(provided: Reviewer.arguments.files.raw, keywords: Reviewer.arguments.keywords)
        @provided = Array(provided)
        @keywords = Array(keywords)
      end

      # Provides the full list of file/path values derived from the command-line arguments
      #
      # @return [Array<String>] full collection of the file arguments as a string
      def to_a
        file_list
      end

      # Provides the full list of file/path values derived from the command-line arguments
      #
      # @return [String] comma-separated string of the derived tag values
      def to_s
        to_a.join(',')
      end

      # Summary of the state of the file arguments
      #
      # @return [Hash<Symbol, Array<String>>] summarizes all of the resulting file values
      def to_h
        {
          provided: provided.sort,
          from_keywords: from_keywords
        }
      end
      alias inspect to_h

      private

      # Combines the sorted list of unique files/paths by merging the explicitly-provided file
      #   arguments as well as those that were translated from any relevant keyword arguments.
      #
      # @return [Array] full list of files/paths passed via command-line including those extracted
      #   as a result of a keyword argument like `staged`
      def file_list
        @file_list ||= [
          *provided,
          *from_keywords
        ].compact.sort.uniq
      end

      # Converts relevant keywords to the list of files they implicitly represent.
      #
      # @return [Array<String>] list of files/paths translated from any keyword arguments that
      #   represent a list of files
      def from_keywords
        return [] unless keywords.any?

        keywords.map do |keyword|
          next unless respond_to?(keyword.to_sym, true)

          send(keyword.to_sym)
        end.flatten.compact.uniq
      end

      # If `staged` is passed as a keyword via the command-line, this will get the list of staged
      #   files via Git
      #
      # @return [Array] list of the currently staged files
      def staged
        # Use git for list of staged fields
        ::Reviewer::Keywords::Git::Staged.list
      end
    end
  end
end

# frozen_string_literal: true

require 'open3'

require_relative 'files/branch_point'

module Reviewer
  class Arguments
    # Generates a Ruby-friendly list (Array) of files to run the command against from the provided
    # command line arguments
    class Files
      attr_reader :provided, :keywords

      alias raw provided

      # Generates an instance of files from the provided arguments
      # @param provided [Array<String>] file arguments provided
      #   directly via the -f or --files flag on the command line
      # @param keywords [Array<String>] reserved keywords that can potentially
      #   be translated to a list of files (e.g. 'staged', 'modified')
      # @param output [Output] the console output handler
      # @param on_git_error [Proc, nil] callback invoked with the error message
      #   when a git command fails (nil silently swallows the error)
      #
      # @example Using the `-f` flag: `rvw -f ./file.rb`
      #   reviewer = Reviewer::Arguments::Files.new(provided: ['./file.rb'], keywords: [])
      #   reviewer.to_a # => ['./file.rb']
      # @example Using the `--files` flag: `rvw --files ./file.rb,./directory/file.rb
      #   reviewer = Reviewer::Arguments::Files.new(provided: ['./file.rb','./directory/file.rb'], keywords: [])
      #   reviewer.to_a # => ['./file.rb','./directory/file.rb']
      #
      # @return [self]
      def initialize(provided: [], keywords: [], output: Output.new, on_git_error: nil)
        @provided = Array(provided)
        @keywords = Array(keywords)
        @output = output
        @on_git_error = on_git_error
      end

      # Provides the full list of file/path values derived from the command-line arguments
      #
      # @return [Array<String>] full collection of the file arguments as a string
      def to_a = file_list

      # Provides the full list of file/path values derived from the command-line arguments
      #
      # @return [String] comma-separated string of the derived file values
      def to_s = to_a.join(',')

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

      # Why `branched` couldn't select files. `branched` never substitutes another ref, so the
      # caller reports this instead of reviewing nothing.
      #
      # @return [Symbol, nil] the missing piece (see BranchPoint#missing), or nil when the branch
      #   point was found or `branched` wasn't requested
      def missing_base
        branch_point.missing if keywords.include?('branched')
      end

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
          method_name = keyword.to_sym
          next unless respond_to?(method_name, true)

          send(method_name)
        end.flatten.compact.uniq
      end

      def staged
        git_files(%w[diff --staged --name-only])
      end

      def unstaged
        git_files(%w[diff --name-only])
      end

      def modified
        git_files(%w[diff --name-only HEAD])
      end

      def untracked
        git_files(%w[ls-files --others --exclude-standard])
      end

      # Every file that differs from origin/HEAD since this work split from it, including
      # uncommitted and new files
      def branched
        commit = branch_point.commit
        return [] unless commit

        git_files(%W[diff --name-only #{commit}]) + untracked
      end

      def branch_point = @branch_point ||= BranchPoint.new

      # Executes a git command and returns the output as an array of file paths. Git escapes
      # non-ASCII paths unless `core.quotePath` is off, and its output is read as UTF-8 like any
      # other command output so the paths match the real files regardless of locale.
      # @param options [Array<String>] the git command options
      #
      # @return [Array<String>] the output lines from the command
      def git_files(options)
        command = (%w[git -c core.quotePath=false --no-pager] + options).join(' ')
        stdout, stderr, status = Open3.capture3(command)

        return Shell::Result.decode(stdout).split("\n").reject(&:empty?) if status.success?

        raise SystemCallError.new("Git Error: #{stderr} (#{command})", status.exitstatus.to_i)
      rescue SystemCallError => e
        @on_git_error&.call(e.message)
        []
      end
    end
  end
end

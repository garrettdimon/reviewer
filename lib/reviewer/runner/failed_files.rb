# frozen_string_literal: true

module Reviewer
  class Runner
    # Extracts file paths from tool output so that subsequent re-runs can be scoped
    # to only the files that had issues.
    #
    # Merges stdout and stderr before scanning because linters (rubocop, reek, etc.)
    # write findings to stdout, not stderr. No common tool splits output with
    # "passing files" on stdout and "failing files" on stderr, so merging is safe.
    # The regex pattern and File.exist? guard filter out any incidental matches.
    class FailedFiles
      # Matches relative path-like tokens at or near the start of a line, allowing
      # leading whitespace for tools that indent output (reek groupings, rspec nesting).
      # Rejects absolute paths (starting with /) to exclude Ruby runtime warnings and
      # gem internals that would otherwise match. Tool findings always use relative
      # paths from the project root. Supports any file extension so non-Ruby tools
      # (eslint, stylelint) also work. File.exist? in to_a provides a final guard.
      #
      #   lib/foo.rb:45:3: C: Style/... (rubocop)
      #   test/foo_test.rb:45 (minitest)
      #   lib/foo.rb -- message (reek)
      #   src/app.js:10:5: error ... (eslint)
      FILE_PATH_PATTERN = %r{^\s*([^/\s]\S*\.\w+)(?::\d| -- )}

      attr_reader :stdout, :stderr

      # Creates a failed-file extractor from captured tool output
      # @param stdout [String, nil] captured standard output from the tool
      # @param stderr [String, nil] captured standard error from the tool
      #
      # @return [FailedFiles]
      def initialize(stdout, stderr)
        @stdout = stdout
        @stderr = stderr
      end

      # Regex-matched paths filtered to only those that exist on disk, deduplicated.
      # @return [Array<String>] unique file paths that exist in the working directory
      def to_a
        matched_paths.select { |path| File.exist?(path) }.uniq
      end

      # All regex-matched paths before filesystem filtering. Useful for testing
      # pattern matching without requiring real files on disk.
      # @return [Array<String>] raw paths extracted from combined output
      def matched_paths
        combined_output.scan(FILE_PATH_PATTERN).flatten
      end

      private

      # Merges both streams and strips ANSI escape codes before scanning. Linters
      # write diagnostic output (file paths with line numbers) to stdout, while
      # stderr typically only contains crash or startup errors. Scanning both catches
      # paths regardless of which stream the tool uses. ANSI codes are stripped via
      # Rainbow::StringUtils.uncolor because tools run with --color embed escape
      # sequences around file paths, which would otherwise become part of the
      # captured path string.
      # @return [String] merged stdout and stderr, stripped of ANSI codes
      def combined_output
        Rainbow::StringUtils.uncolor([stdout, stderr].compact.join("\n"))
      end
    end
  end
end

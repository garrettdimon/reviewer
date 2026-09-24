# frozen_string_literal: true

require_relative '../output/formatting'

module Reviewer
  class Session
    # Display logic for lifecycle warnings: unrecognized keywords, no matching tools, etc.
    class Formatter
      include Output::Formatting

      MISSING_FILES_MESSAGE = 'The --files option requires at least one file or path.'

      BRANCHED_HINT = "'branched' always compares against origin/HEAD and doesn't take a branch name"

      attr_reader :output, :printer
      private :output, :printer

      # Creates a formatter for session lifecycle warnings
      # @param output [Output] the console output handler
      #
      # @return [Formatter]
      def initialize(output)
        @output = output
        @printer = output.printer
      end

      # Displays warnings for keywords that don't match any tool or git scope
      # @param unrecognized [Array<String>] the unrecognized keyword strings
      # @param suggestions [Hash{String => String}] keyword => suggested correction
      # @param hint [String, nil] a closing note about how the request was misread
      #
      # @return [void]
      def unrecognized_keywords(unrecognized, suggestions, hint = nil)
        unrecognized.each do |keyword|
          printer.puts(:warning, "Unrecognized: #{keyword}")
          suggestion = suggestions[keyword]
          printer.puts(:muted, "  did you mean '#{suggestion}'?") if suggestion
        end
        printer.puts(:muted, hint) if hint
        output.newline
      end

      # Renders a machine-readable envelope for a name Reviewer cannot honour
      # @param unrecognized [Array<String>] the names that matched nothing
      # @param suggestions [Hash] closest known name per unrecognized name
      # @param hint [String, nil] a note about how the request was misread, omitted when nil
      #
      # @return [void]
      def unrecognized_keywords_json(unrecognized, suggestions, hint = nil)
        payload = {
          schema_version: Report::SCHEMA_VERSION,
          state: 'error',
          error: {
            code: 'unrecognized_selector',
            message: "Unrecognized: #{unrecognized.join(', ')}",
            suggestions: suggestions,
            hint: hint
          }.compact,
          summary: Report.empty_summary,
          tools: []
        }

        printer.write_raw("#{JSON.pretty_generate(payload)}\n")
      end

      # Displays a usage error when -f/--files has no value
      #
      # @return [void]
      def missing_files_option
        printer.puts(:warning, MISSING_FILES_MESSAGE)
        output.newline
      end

      # Renders the machine-readable form of the missing files usage error
      #
      # @return [void]
      def missing_files_option_json
        payload = {
          schema_version: Report::SCHEMA_VERSION,
          state: 'error',
          error: { code: 'missing_files', message: MISSING_FILES_MESSAGE },
          summary: Report.empty_summary,
          tools: []
        }

        printer.write_raw("#{JSON.pretty_generate(payload)}\n")
      end

      # Displays a usage error when `branched` can't find where the work split from origin/HEAD
      # @param missing [Arguments::Files::BranchPoint::Missing] why the branch point wasn't found
      #
      # @return [void]
      def missing_base(missing)
        printer.puts(:warning, missing.problem)
        printer.puts(:muted, missing.fix)
        output.newline
      end

      # Renders the machine-readable form of the missing base usage error
      # @param missing [Arguments::Files::BranchPoint::Missing] why the branch point wasn't found
      #
      # @return [void]
      def missing_base_json(missing)
        payload = {
          schema_version: Report::SCHEMA_VERSION,
          state: 'error',
          error: { code: 'missing_base', message: missing.message },
          summary: Report.empty_summary,
          tools: []
        }

        printer.write_raw("#{JSON.pretty_generate(payload)}\n")
      end

      # Displays a warning when an unrecognized output format is requested
      # @param value [String] the invalid format name
      # @param known [Array<Symbol>] the valid format options
      #
      # @return [void]
      def invalid_format(value, known)
        printer.puts(:warning, "Unknown format '#{value}', using 'streaming'")
        printer.puts(:muted, "Valid formats: #{known.join(', ')}")
        output.newline
      end

      # Displays a git-related error with context-appropriate messaging
      # @param message [String] the error message from the git command
      #
      # @return [void]
      def git_error(message)
        if message.include?('not a git repository')
          printer.puts(:warning, 'Not a git repository')
          printer.puts(:muted, 'Git keywords (staged, modified, etc.) require a git repository')
        else
          printer.puts(:warning, 'Git command failed')
          printer.puts(:muted, message)
          printer.puts(:muted, 'Continuing without file filtering')
        end
      end

      # Displays a message when file-scoping keywords resolved to no files
      # @param keywords [Array<String>] the file keywords that were requested (e.g. ['staged'])
      #
      # @return [void]
      def no_reviewable_files(keywords:)
        output.newline
        printer.puts(:muted, "No reviewable #{keywords.join(', ')} files found")
        output.newline
      end

      # Displays a warning when no configured tools match the requested names or tags
      # @param requested [Array<String>] tool names or tags the user asked for
      # @param available [Array<String>] all configured tool keys
      #
      # @return [void]
      def no_matching_tools(requested:, available:)
        output.newline
        printer.puts(:warning, 'No matching tools found')
        printer.puts(:muted, "Requested: #{requested.join(', ')}") if requested.any?
        printer.puts(:muted, "Available: #{available.join(', ')}") if available.any?
        output.newline
      end
    end
  end
end

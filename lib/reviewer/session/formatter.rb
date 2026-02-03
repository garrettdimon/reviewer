# frozen_string_literal: true

require_relative '../output/formatting'

module Reviewer
  class Session
    # Display logic for lifecycle warnings: unrecognized keywords, no matching tools, etc.
    class Formatter
      include Output::Formatting

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
      #
      # @return [void]
      def unrecognized_keywords(unrecognized, suggestions)
        unrecognized.each do |keyword|
          printer.puts(:warning, "Unrecognized: #{keyword}")
          suggestion = suggestions[keyword]
          printer.puts(:muted, "  did you mean '#{suggestion}'?") if suggestion
        end
        output.newline
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

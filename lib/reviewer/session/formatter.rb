# frozen_string_literal: true

require_relative '../output/formatting'

module Reviewer
  class Session
    # Display logic for lifecycle warnings: unrecognized keywords, no matching tools, etc.
    class Formatter
      include Output::Formatting

      def initialize(output)
        @output = output
        @printer = output.printer
      end

      def unrecognized_keywords(unrecognized, suggestions)
        unrecognized.each do |keyword|
          @printer.puts(:warning, "Unrecognized: #{keyword}")
          suggestion = suggestions[keyword]
          @printer.puts(:muted, "  did you mean '#{suggestion}'?") if suggestion
        end
        @output.newline
      end

      def invalid_format(value, known)
        @printer.puts(:warning, "Unknown format '#{value}', using 'streaming'")
        @printer.puts(:muted, "Valid formats: #{known.join(', ')}")
        @output.newline
      end

      def git_error(message)
        if message.include?('not a git repository')
          @printer.puts(:warning, 'Not a git repository')
          @printer.puts(:muted, 'Git keywords (staged, modified, etc.) require a git repository')
        else
          @printer.puts(:warning, 'Git command failed')
          @printer.puts(:muted, message)
          @printer.puts(:muted, 'Continuing without file filtering')
        end
      end

      def no_matching_tools(requested:, available:)
        @output.newline
        @printer.puts(:warning, 'No matching tools found')
        @printer.puts(:muted, "Requested: #{requested.join(', ')}") if requested.any?
        @printer.puts(:muted, "Available: #{available.join(', ')}") if available.any?
        @output.newline
      end
    end
  end
end

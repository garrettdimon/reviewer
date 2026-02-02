# frozen_string_literal: true

require_relative 'session/formatter'

module Reviewer
  # Run lifecycle with full dependency injection.
  # Owns the review/format lifecycle that was previously in Reviewer module methods.
  class Session
    attr_reader :arguments, :tools, :output, :history, :prompt, :configuration, :formatter
    private :arguments, :tools, :output, :history, :prompt, :configuration, :formatter

    # Creates a session with all dependencies injected
    # @param arguments [Arguments] parsed CLI arguments
    # @param tools [Tools] the collection of configured tools
    # @param output [Output] console output handler
    # @param history [History] YAML store for run history and timing
    # @param prompt [Prompt] interactive prompt for yes/no questions
    # @param configuration [Configuration] the loaded .reviewer.yml configuration
    #
    # @return [Session]
    def initialize(arguments:, tools:, output:, history:, prompt:, configuration:)
      @arguments = arguments
      @tools = tools
      @output = output
      @history = history
      @prompt = prompt
      @configuration = configuration
      @formatter = Session::Formatter.new(output)
    end

    # Runs the review command for the current set of tools
    # @param clear_screen [Boolean] whether to clear the screen before running
    #
    # @return [Integer] the maximum exit status from all tools
    def review(clear_screen: false)
      run_tools(:review, clear_screen: clear_screen)
    end

    # Runs the format command for the current set of tools
    # @param clear_screen [Boolean] whether to clear the screen before running
    #
    # @return [Integer] the maximum exit status from all tools
    def format(clear_screen: false)
      run_tools(:format, clear_screen: clear_screen)
    end

    private

    def run_tools(command_type, clear_screen: false)
      return 0 if handle_missing_configuration?
      return 0 if handle_failed_with_nothing_to_run?

      if json_output?
        run_json(command_type)
      else
        run_text(command_type, clear_screen: clear_screen)
      end
    end

    def run_json(command_type)
      current_tools = tools.current
      return 0 if current_tools.empty?

      report = Batch.new(command_type, current_tools, output: output, arguments: arguments).run
      puts report.to_json
      report.max_exit_status
    end

    def run_text(command_type, clear_screen: false)
      output.clear if clear_screen
      warn_unrecognized_keywords

      current_tools = tools.current
      return warn_no_matching_tools if current_tools.empty?

      show_run_summary(current_tools, command_type)

      report = Batch.new(command_type, current_tools, output: output, arguments: arguments).run
      display_text_report(report)
      show_missing_tools(report)

      report.max_exit_status
    end

    def warn_no_matching_tools
      formatter.no_matching_tools(
        requested: arguments.keywords.provided + arguments.tags.to_a,
        available: tools.all.map { |tool| tool.key.to_s }
      )
      0
    end

    def json_output?
      arguments.json?
    end

    def warn_unrecognized_keywords
      unrecognized = arguments.keywords.unrecognized
      return if unrecognized.empty?

      suggestions = build_suggestions(unrecognized)
      formatter.unrecognized_keywords(unrecognized, suggestions)
    end

    def build_suggestions(unrecognized)
      possible = arguments.keywords.possible
      checker = DidYouMean::SpellChecker.new(dictionary: possible)

      unrecognized.each_with_object({}) do |keyword, map|
        corrections = checker.correct(keyword)
        map[keyword] = corrections.first if corrections.any?
      end
    end

    # Returns true if configuration is missing (caller should return early)
    def handle_missing_configuration?
      return false if configuration.file.exist?

      output.first_run_greeting
      if prompt.yes?('Would you like to set it up now?')
        Setup.run
      else
        output.first_run_skip
      end
      true
    end

    # Returns true if failed keyword is present with nothing to re-run (caller should return early)
    def handle_failed_with_nothing_to_run?
      return false unless failed_with_nothing_to_run?

      display_failed_empty_message
      true
    end

    def failed_with_nothing_to_run?
      keywords = arguments.keywords
      keywords.failed? &&
        tools.failed_from_history.empty? &&
        keywords.for_tool_names.empty? &&
        arguments.tags.to_a.empty?
    end

    def display_failed_empty_message
      if tools.all.any? { |tool| history.get(tool.key, :last_status) }
        batch_formatter.no_failures_to_retry
      else
        batch_formatter.no_previous_run
      end
    end

    def display_text_report(report)
      if arguments.format == :summary
        Report::Formatter.new(report, output: output).print
      elsif report.success?
        ran_count = report.results.count { |result| !result.missing? && !result.skipped? }
        batch_formatter.batch_summary(ran_count, report.duration)
      end
    end

    def show_missing_tools(report)
      return unless report.missing?

      batch_formatter.missing_tools(report.missing_tools)
    end

    def show_run_summary(current_tools, command_type)
      return unless arguments.keywords.provided.any?

      entries = build_run_summary(current_tools, command_type)
      return if entries.size <= 1 && entries.none? { |entry| entry[:files].any? }

      batch_formatter.run_summary(entries)
    end

    def build_run_summary(current_tools, command_type)
      current_tools.filter_map do |tool|
        Command.new(tool, command_type, arguments: arguments).run_summary
      end
    end

    def batch_formatter
      Batch::Formatter.new(output)
    end
  end
end

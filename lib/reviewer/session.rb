# frozen_string_literal: true

require_relative 'session/formatter'

module Reviewer
  # Run lifecycle with full dependency injection.
  # Owns the review/format lifecycle that was previously in Reviewer module methods.
  class Session
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
      @output.clear if clear_screen && !@arguments.json?

      return 0 if handle_missing_configuration!
      warn_unrecognized_keywords!
      return 0 if handle_failed_with_nothing_to_run!

      run_and_report(command_type)
    end

    def run_and_report(command_type)
      current_tools = @tools.current
      return warn_no_matching_tools if current_tools.empty?

      show_run_summary(current_tools, command_type)

      report = Batch.new(command_type, current_tools, output: @output, arguments: @arguments).run
      display_report(report)

      report.max_exit_status
    end

    def warn_no_matching_tools
      @formatter.no_matching_tools(
        requested: @arguments.keywords.provided + @arguments.tags.to_a,
        available: @tools.all.map { |tool| tool.key.to_s }
      )
      0
    end

    def warn_unrecognized_keywords!
      return if @arguments.json?

      unrecognized = @arguments.keywords.unrecognized
      return if unrecognized.empty?

      suggestions = build_suggestions(unrecognized)
      @formatter.unrecognized_keywords(unrecognized, suggestions)
    end

    def build_suggestions(unrecognized)
      possible = @arguments.keywords.possible
      checker = DidYouMean::SpellChecker.new(dictionary: possible)

      unrecognized.each_with_object({}) do |keyword, map|
        corrections = checker.correct(keyword)
        map[keyword] = corrections.first if corrections.any?
      end
    end

    # Returns true if configuration is missing (caller should return early)
    def handle_missing_configuration!
      return false if @configuration.file.exist?

      @output.first_run_greeting
      if @prompt.yes?('Would you like to set it up now?')
        Setup.run
      else
        @output.first_run_skip
      end
      true
    end

    # Returns true if failed keyword is present with nothing to re-run (caller should return early)
    def handle_failed_with_nothing_to_run!
      return false unless failed_with_nothing_to_run?

      display_failed_empty_message
      true
    end

    def failed_with_nothing_to_run?
      keywords = @arguments.keywords
      keywords.failed? &&
        @tools.failed_from_history.empty? &&
        keywords.for_tool_names.empty? &&
        @arguments.tags.to_a.empty?
    end

    def display_failed_empty_message
      if @tools.all.any? { |tool| @history.get(tool.key, :last_status) }
        @output.no_failures_to_retry
      else
        @output.no_previous_run
      end
    end

    def display_report(report)
      if @arguments.json?
        puts report.to_json
        return
      end

      display_text_report(report)
      show_missing_tools(report)
    end

    def display_text_report(report)
      if @arguments.format == :summary
        Report::Formatter.new(report, output: @output).print
      elsif report.success?
        ran_count = report.results.count { |result| !result.missing? && !result.skipped? }
        @output.batch_summary(ran_count, report.duration)
      end
    end

    def show_missing_tools(report)
      return unless report.missing?

      missing = report.missing_results.map { |result| Tool.new(result.tool_key) }
      @output.missing_tools(missing)
    end

    def show_run_summary(current_tools, command_type)
      return unless @arguments.keywords.provided.any?
      return if @arguments.json?

      entries = build_run_summary(current_tools, command_type)
      return if entries.size <= 1 && entries.none? { |entry| entry[:files].any? }

      @output.run_summary(entries)
    end

    def build_run_summary(current_tools, command_type)
      current_tools.filter_map do |tool|
        cmd = Command.new(tool, command_type, arguments: @arguments)
        next if cmd.skip?

        { name: tool.name, files: cmd.target_files }
      end
    end
  end
end

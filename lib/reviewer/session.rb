# frozen_string_literal: true

require_relative 'session/formatter'

module Reviewer
  # Run lifecycle with full dependency injection.
  # Owns the review/format lifecycle that was previously in Reviewer module methods.
  class Session
    # Exit status for a usage error -- the caller asked for something Reviewer
    # cannot honour. Distinct from a tool failure so the two can be told apart.
    USAGE_ERROR = 2

    attr_reader :context, :tools
    private :context, :tools

    # Creates a session with all dependencies injected
    # @param context [Context] the shared runtime dependencies (arguments, output, history)
    # @param tools [Tools] the collection of configured tools
    #
    # @return [Session]
    def initialize(context:, tools:)
      @context = context
      @tools = tools
      context.arguments.keywords.tools = tools
    end

    # Runs the review command for the current set of tools
    #
    # @return [Integer] the maximum exit status from all tools
    def review
      run_tools(:review)
    end

    # Runs the format command for the current set of tools
    #
    # @return [Integer] the maximum exit status from all tools
    def format
      run_tools(:format)
    end

    private

    def arguments = context.arguments
    def output = context.output
    def history = context.history

    def run_tools(command_type)
      return reject_unrecognized_selectors if unrecognized_selectors.any?

      if json_output?
        run_json(command_type)
      else
        run_text(command_type)
      end
    end

    def run_json(command_type)
      message = json_early_exit_message
      return emit_json_early_exit(message) if message

      current_tools = tools.current
      return 0 if current_tools.empty?

      strategy = runner_strategy(current_tools)
      report = Batch.new(command_type, current_tools, strategy: strategy, context: context).run
      puts report.to_json
      report.max_exit_status
    end

    def run_text(command_type)
      return 0 if handle_failed_with_nothing_to_run?
      return 0 if handle_file_scoping_with_no_files?

      current_tools = tools.current
      return warn_no_matching_tools if current_tools.empty?

      show_run_summary(current_tools, command_type)

      strategy = runner_strategy(current_tools)
      report = Batch.new(command_type, current_tools, strategy: strategy, context: context).run
      display_text_report(report)
      show_missing_tools(report, current_tools)

      report.max_exit_status
    end

    # A name Reviewer does not recognize stops the run. Resolving it to the full
    # batch means reporting success for checks the caller never asked for, and
    # attributing that success to a tool that never ran.
    def reject_unrecognized_selectors
      names = unrecognized_selectors
      suggestions = build_suggestions(names)

      if json_output?
        formatter.unrecognized_keywords_json(names, suggestions)
      else
        formatter.unrecognized_keywords(names, suggestions)
      end

      USAGE_ERROR
    end

    # Positional selectors and `-t` values are the same request spelled two ways,
    # so an unknown name has to fail the same either way. Keywords already track
    # their own unrecognized set; tags are only checked against the configured
    # vocabulary, since `-t` accepts nothing else.
    def unrecognized_selectors
      (arguments.keywords.unrecognized + unrecognized_tags).uniq.sort
    end

    def unrecognized_tags
      configured = arguments.keywords.configured_tags

      arguments.tags.raw.map(&:to_s).reject { |tag| configured.include?(tag) }
    end

    def warn_no_matching_tools
      formatter.no_matching_tools(
        requested: arguments.keywords.provided + arguments.tags.to_a,
        available: tools.all.map { |tool| tool.key.to_s }
      )
      0
    end

    def json_output?
      arguments.format == :json
    end

    def json_early_exit_message
      if failed_with_nothing_to_run?
        'No failures to retry'
      elsif file_scoping_with_no_files?
        "No reviewable #{arguments.files.keywords.join(', ')} files found"
      end
    end

    def emit_json_early_exit(message)
      puts JSON.pretty_generate(
        success: true,
        message: message,
        summary: { total: 0, passed: 0, failed: 0, missing: 0, duration: 0 },
        tools: []
      )
      0
    end

    def build_suggestions(unrecognized)
      possible = arguments.keywords.possible
      checker = DidYouMean::SpellChecker.new(dictionary: possible)

      unrecognized.each_with_object({}) do |keyword, map|
        corrections = checker.correct(keyword)
        map[keyword] = corrections.first if corrections.any?
      end
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
        keywords.for_tags.empty? &&
        arguments.tags.to_a.empty?
    end

    # Returns true if file keywords were provided but resolved to no files (caller should return early)
    def handle_file_scoping_with_no_files?
      return false unless file_scoping_with_no_files?

      formatter.no_reviewable_files(keywords: arguments.files.keywords)
      true
    end

    def file_scoping_with_no_files?
      arguments.files.keywords.any? && arguments.files.to_a.empty?
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
        ran_count = report.results.count(&:executed?)
        batch_formatter.summary(ran_count, report.duration)
      end
    end

    def show_missing_tools(report, current_tools)
      return unless report.missing?

      batch_formatter.missing_tools(report.missing_tools, tools: current_tools)
    end

    def show_run_summary(current_tools, command_type)
      return unless arguments.keywords.provided.any?

      entries = build_run_summary(current_tools, command_type)
      return if entries.size <= 1 && entries.none? { |entry| entry[:files].any? }

      batch_formatter.run_summary(entries)
    end

    def build_run_summary(current_tools, command_type)
      current_tools.filter_map do |tool|
        Command.new(tool, command_type, context: context).run_summary
      end
    end

    def runner_strategy(current_tools)
      arguments.runner_strategy(multiple_tools: current_tools.size > 1)
    end

    def formatter = @formatter ||= Session::Formatter.new(output)

    def batch_formatter
      Batch::Formatter.new(output)
    end
  end
end

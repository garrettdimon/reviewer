# frozen_string_literal: true

require 'benchmark'
require 'forwardable'
# require 'logger'
require 'rainbow'

require_relative 'reviewer/conversions'

require_relative 'reviewer/arguments'
require_relative 'reviewer/batch'
require_relative 'reviewer/capabilities'
require_relative 'reviewer/command'
require_relative 'reviewer/configuration'
require_relative 'reviewer/failed_files'
require_relative 'reviewer/guidance'
require_relative 'reviewer/history'
require_relative 'reviewer/keywords'
require_relative 'reviewer/loader'
require_relative 'reviewer/output'
require_relative 'reviewer/report'
require_relative 'reviewer/runner'
require_relative 'reviewer/shell'
require_relative 'reviewer/tool'
require_relative 'reviewer/tools'
require_relative 'reviewer/setup'
require_relative 'reviewer/version'

# Primary interface for the reviewer tools
module Reviewer
  # Base error class for all Reviewer errors
  class Error < StandardError; end

  class << self
    # Resets the loaded tools and arguments
    def reset! = @tools = @arguments = nil

    # Runs the `review` command for the specified tools/files. Reviewer expects all configured
    #   commands that are not disabled to have an entry for the `review` command.
    # @param clear_screen [boolean] clears the screen to reduce noise when true
    #
    # @return [void] Prints output to the console
    def review(clear_screen: false)
      return perform(:init) if subcommand?(:init)

      perform(:review, clear_screen: clear_screen)
    end

    # Runs the `format` command for the specified tools/files for which it is configured.
    # @param clear_screen [boolean] clears the screen to reduce noise when true
    #
    # @return [void] Prints output to the console
    def format(clear_screen: false)
      return perform(:init) if subcommand?(:init)

      perform(:format, clear_screen: clear_screen)
    end

    # The collection of arguments that were passed via the command line.
    #
    # @return [Reviewer::Arguments] exposes tags, files, and keywords from arguments
    def arguments = @arguments ||= Arguments.new

    # An interface for the collection of configured tools for accessing subsets of tools
    #   based on enabled/disabled, tags, keywords, etc.
    #
    # @return [Reviewer::Tools] exposes the set of tools to be run in a given context
    def tools = @tools ||= Tools.new

    # The primary output method for Reviewer to consistently display success/failure details for a
    #   unique run of each tool and the collective summary when relevant.
    #
    # @return [Reviewer::Output] prints formatted output to the console.
    def output = @output ||= Output.new

    # A file store for sharing information across runs
    #
    # @return [Reviewer::History] a YAML::Store (or Pstore) containing data on tools
    def history = @history ||= History.new

    # Exposes the configuration options for Reviewer.
    #
    # @return [Reviewer::Configuration] configuration settings instance
    def configuration = @configuration ||= Configuration.new

    # A block approach to configuring Reviewer.
    #
    # @example Set configuration file path
    #   Reviewer.configure do |config|
    #     config.file = '~/configuration.yml'
    #   end
    #
    # @return [Reviewer::Configuration] Reviewer configuration settings
    def configure = yield(configuration)

    private

    def subcommand?(name) = ARGV.first == name.to_s

    # Central dispatcher for all command types (:review, :format, :init, and eventually :install)
    def perform(command_type, clear_screen: false)
      return Setup.run if command_type == :init

      prepare_run(clear_screen)
      exit run_and_report(command_type)
    end

    def prepare_run(clear_screen)
      output.clear if clear_screen && !arguments.json?
      guard_missing_configuration!
      guard_failed_with_nothing_to_run!
    end

    def run_and_report(command_type)
      current_tools = tools.current
      show_run_summary(current_tools, command_type)

      report = Batch.new(command_type, current_tools).run
      display_report(report)

      report.max_exit_status
    end

    # Exits with guidance when .reviewer.yml is missing
    def guard_missing_configuration!
      return if configuration.file.exist?

      output.missing_configuration(configuration.file)
      exit 0
    end

    # Exits early when `failed` keyword is used but there's nothing to re-run
    def guard_failed_with_nothing_to_run!
      return unless failed_with_nothing_to_run?

      display_failed_empty_message
      exit 0
    end

    # Whether the `failed` keyword was used as the sole keyword but there are no failed tools
    #
    # @return [Boolean] true if failed keyword is present with nothing to re-run
    def failed_with_nothing_to_run?
      keywords = arguments.keywords
      keywords.failed? &&
        tools.failed_from_history.empty? &&
        keywords.for_tool_names.empty? &&
        arguments.tags.to_a.empty?
    end

    # Distinguishes "no previous run" from "no failures" and displays the appropriate message
    #
    # @return [void]
    def display_failed_empty_message
      if tools.all.any? { |tool| Reviewer.history.get(tool.key, :last_status) }
        output.no_failures_to_retry
      else
        output.no_previous_run
      end
    end

    # Outputs the report in the appropriate format based on arguments
    #
    # @param report [Report] the report to display
    # @return [void]
    def display_report(report)
      if arguments.json?
        puts report.to_json
        return
      end

      if arguments.format == :summary
        Report::Formatter.new(report, output: output).print
      elsif report.success?
        ran_count = report.results.count { |r| !r.missing && !r.skipped }
        output.batch_summary(ran_count, report.duration)
      end

      show_missing_tools(report)
    end

    # Shows a consolidated summary of missing tools with install hints
    #
    # @param report [Report] the report to check for missing tools
    # @return [void]
    def show_missing_tools(report)
      return unless report.missing?

      missing = report.missing_results.map { |r| Tool.new(r.tool_key) }
      output.missing_tools(missing)
    end

    def show_run_summary(current_tools, command_type)
      return unless arguments.keywords.provided.any?
      return if arguments.json?

      entries = build_run_summary(current_tools, command_type)
      return if entries.size <= 1 && entries.none? { |entry| entry[:files].any? }

      output.run_summary(entries)
    end

    def build_run_summary(current_tools, command_type)
      current_tools.filter_map do |tool|
        cmd = Command.new(tool, command_type)
        next if cmd.skip?

        { name: tool.name, files: cmd.target_files }
      end
    end
  end
end

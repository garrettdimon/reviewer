# frozen_string_literal: true

require 'benchmark'
require 'forwardable'
require 'rainbow'

require_relative 'reviewer/configuration'
require_relative 'reviewer/configuration/loader'
require_relative 'reviewer/context'
require_relative 'reviewer/history'
require_relative 'reviewer/tool'
require_relative 'reviewer/tools'

require_relative 'reviewer/arguments'
require_relative 'reviewer/batch'
require_relative 'reviewer/capabilities'
require_relative 'reviewer/command'
require_relative 'reviewer/output'
require_relative 'reviewer/prompt'
require_relative 'reviewer/report'
require_relative 'reviewer/runner'
require_relative 'reviewer/session'
require_relative 'reviewer/shell'
require_relative 'reviewer/setup'
require_relative 'reviewer/doctor'
require_relative 'reviewer/version'

# Primary interface for the reviewer tools
module Reviewer
  # Base error class for all Reviewer errors
  class Error < StandardError; end

  class << self
    # Resets the loaded tools and arguments
    def reset! = @tools = @arguments = @prompt = @output = @history = @configuration = nil

    # Runs the `review` command for the specified tools/files. Reviewer expects all configured
    #   commands that are not disabled to have an entry for the `review` command.
    #
    # @return [void] Prints output to the console
    def review
      handle_early_exits { exit build_session.review }
    end

    # Runs the `format` command for the specified tools/files for which it is configured.
    #
    # @return [void] Prints output to the console
    def format
      handle_early_exits { exit build_session.format }
    end

    # The collection of arguments that were passed via the command line.
    #
    # @return [Reviewer::Arguments] exposes tags, files, and keywords from arguments
    def arguments = @arguments ||= Arguments.new

    # An interface for the collection of configured tools for accessing subsets of tools
    #   based on enabled/disabled, tags, keywords, etc.
    #
    # @return [Reviewer::Tools] exposes the set of tools to be run in a given context
    def tools = @tools ||= Tools.new(arguments: arguments, history: history, config_file: configuration.file)

    # The primary output method for Reviewer to consistently display success/failure details for a
    #   unique run of each tool and the collective summary when relevant.
    #
    # @return [Reviewer::Output] prints formatted output to the console.
    def output = @output ||= Output.new

    # A file store for sharing information across runs
    #
    # @return [Reviewer::History] a YAML::Store (or Pstore) containing data on tools
    def history = @history ||= History.new(file: configuration.history_file)

    # An interactive prompt for yes/no questions
    #
    # @return [Reviewer::Prompt] prompt instance wrapping stdin/stdout
    def prompt = @prompt ||= Prompt.new

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

    def handle_early_exits
      return show_help if arguments.help?
      return show_version if arguments.version?
      return Setup.run if subcommand?(:init)
      return run_doctor if subcommand?(:doctor)
      return run_capabilities if capabilities_flag?
      return run_first_time_setup unless configuration.file.exist?

      yield
    end

    def subcommand?(name) = ARGV.first == name.to_s
    def capabilities_flag? = ARGV.include?('--capabilities') || ARGV.include?('-c')

    def show_help
      output.help(help_text)
    end

    def help_text
      <<~HELP
        Usage: rvw [tool or tag ...] [keyword ...] [options]
               fmt [tool or tag ...] [keyword ...] [options]

        Commands:
            rvw                          Run all enabled tools
            rvw <tool>                   Run a single tool by its config key
            rvw <tag>                    Run tools matching a tag
            fmt                          Auto-fix with format commands
            rvw init                     Generate .reviewer.yml from Gemfile.lock
            rvw doctor                   Check configuration and tool health

        Keywords:
            staged                       Files staged for commit
            unstaged                     Files with unstaged changes
            modified                     All changed files (staged + unstaged)
            untracked                    New files not yet tracked by git
            failed                       Re-run only tools that failed last time

        Options:
        #{slop_options}

        Examples:
            rvw rubocop                  Run RuboCop only
            rvw staged                   Review staged files across all tools
            rvw -t security modified     Run security-tagged tools on changed files
            rvw tests -f test/user_test.rb   Run tests on a specific file
            rvw failed                   Re-run what failed last time
            fmt rubocop                  Auto-fix with RuboCop
      HELP
    end

    def slop_options
      arguments.options.to_s.lines.drop(1).join.rstrip
    end

    def show_version
      output.help(VERSION)
    end

    def run_capabilities
      puts Capabilities.new(tools: tools).to_json
    end

    def run_doctor
      report = Doctor.run(configuration: configuration, tools: tools)
      Doctor::Formatter.new(output).print(report)
    end

    def run_first_time_setup
      formatter = Setup::Formatter.new(output)
      formatter.first_run_greeting
      if prompt.yes?('Would you like to set it up now?')
        Setup.run(configuration: configuration)
      else
        formatter.first_run_skip
      end
    end

    def build_session
      context = Context.new(arguments: arguments, output: output, history: history)
      Session.new(context: context, tools: tools)
    end
  end
end

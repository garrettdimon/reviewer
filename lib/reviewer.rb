# frozen_string_literal: true

require 'active_support/core_ext/string'
require 'benchmark'

require_relative 'reviewer/arguments'
require_relative 'reviewer/configuration'
require_relative 'reviewer/history'
require_relative 'reviewer/loader'
require_relative 'reviewer/logger'
require_relative 'reviewer/runner'
require_relative 'reviewer/tool'
require_relative 'reviewer/tools'
require_relative 'reviewer/version'

# Primary interface for the reviewer tools
module Reviewer
  class Error < StandardError; end

  class << self
    attr_writer :configuration

    # Runs the `review` command for the specified tools/files. Reviewer expects all configured
    # commands that are not disabled to have an entry for the `review` command.
    # @param clear_streen [boolean] clears the screen to reduce noise when true
    #
    # @return [void] Prints output to the console
    def review(clear_screen: false)
      perform(:review, clear_screen: clear_screen)
    end

    # Runs the `format` command for the specified tools/files for which it is configured.
    # @param clear_streen [boolean] clears the screen to reduce noise when true
    #
    # @return [void] Prints output to the console
    def format(clear_screen: false)
      perform(:format, clear_screen: clear_screen)
    end

    # The collection of arguments that were passed via the command line.
    #
    # @return [Reviewer::Arguments] exposes tags, files, and keywords from arguments
    def arguments
      @arguments ||= Arguments.new
    end

    # An interface for the collection of configured tools for accessing subsets of tools
    # based on enabled/disabled, tags, keywords, etc.
    #
    # @return [Reviewer::Tools] exposes the set of tools to be run in a given context
    def tools
      @tools ||= Tools.new
    end

    # The primary output method for Reviewer to consistently display success/failure details for a
    # unique run of each tool and the collective summary when relevant.
    #
    # @return [Reviewer::Logger] prints formatted output to the command line.
    def logger
      @logger ||= Logger.new
    end

    # A file store for sharing information across runs
    #
    # @return [Reviewer::History] a YAML::Store (or Pstore) containing data on tools
    def history
      @history ||= History.new
    end

    # Exposes the configuration options for Reviewer.
    #
    # @return [Reviewer::Configuration] configuration settings instance
    def configuration
      @configuration ||= Configuration.new
    end

    # A block approach to configuring Reviewer.
    #
    # @example Set configuration file path
    #   Reviewer.configure do |config|
    #     config.file = '~/configuration.yml'
    #   end
    #
    # @return [Reviewer::Configuration] Reviewer configuration settings
    def configure
      yield(configuration)
    end

    private

    # Provides a consistent approach to running and benchmarking commmands and preventing further
    # execution of later tools if a command fails.
    # @param command_type [Symbol] the specific command to run for each tool
    #
    # @example Run the `review` command for each relevant tool
    #   perform(:review)
    #
    # @return [Hash] the exit status (in integer format) for each command run
    def perform(command_type, clear_screen: false)
      system('clear') if clear_screen
      results = {}
      benchmark_suite do
        tools.current.each do |tool|
          runner = Runner.new(tool, command_type, logger: logger)
          exit_status = runner.run
          results[tool.key] = exit_status

          # If the tool fails, stop running other tools
          break unless exit_status <= tool.max_exit_status
        end
      end
      results
    end

    def benchmark_suite(&block)
      logger.total_time(Benchmark.realtime(&block))
    end
  end
end

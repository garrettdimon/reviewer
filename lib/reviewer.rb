# frozen_string_literal: true

require 'active_support/core_ext/string'
require 'benchmark'

require_relative 'reviewer/configuration'
require_relative 'reviewer/arguments'
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

    # Runs the `review` command specified for each tool
    #
    # @return [void] Prints output to the console
    def review
      perform(:review)
    end

    def format
      perform(:format)
    end

    def arguments
      @arguments ||= Arguments.new
    end

    def tools
      @tools ||= Tools.new
    end

    def logger
      @logger ||= Logger.new
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    private

    def perform(command_type)
      results = {}

      elapsed_time = Benchmark.realtime do
        tools.current.each do |tool|
          runner = Runner.new(tool, command_type, logger: logger)
          exit_status = runner.run
          results[tool.key] = exit_status

          # If a single tool fails, stop there.
          break unless exit_status <= tool.max_exit_status
        end
      end
      logger.total_time(elapsed_time)

      results
    end
  end
end

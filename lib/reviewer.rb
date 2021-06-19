# frozen_string_literal: true

require 'active_support/core_ext/string'
require 'benchmark'

require_relative 'reviewer/configuration'
require_relative 'reviewer/arguments'
require_relative 'reviewer/files'
require_relative 'reviewer/loader'
require_relative 'reviewer/logger'
require_relative 'reviewer/runner'
require_relative 'reviewer/tool'
require_relative 'reviewer/version'

# Primary interface for the reviewer tools
module Reviewer
  class Error < StandardError; end

  class << self
    attr_writer :arguments, :configuration, :logger

    def review
      elapsed_time = Benchmark.realtime do
        tools.each do |tool|
          next if tool.disabled?

          exit_status = Runner.new(tool, :review).run

          break unless exit_status <= tool.max_exit_status
        end
      end
      puts "\n➤ Total Time: #{elapsed_time.round(3)}s\n"
    end

    def format
      elapsed_time = Benchmark.realtime do
        tools.each do |tool|
          next if tool.disabled?

          exit_status = Runner.run(tool, :format)

          break unless exit_status <= tool.max_exit_status
        end
      end
      puts "\n➤ Total Time: #{elapsed_time.round(3)}s\n"
    end

    def arguments
      @arguments ||= Arguments.new
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset
      @configuration = Configuration.new
      @arguments = Arguments.new
    end

    def tools
      tools = []
      configuration.tools.each_key do |key|
        tools << Tool.new(key)
      end
      tools
    end
  end
end

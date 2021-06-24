# frozen_string_literal: true

require 'active_support/core_ext/string'
require 'benchmark'

require_relative 'reviewer/configuration'
require_relative 'reviewer/arguments'
require_relative 'reviewer/loader'
require_relative 'reviewer/logger'
require_relative 'reviewer/runner'
require_relative 'reviewer/tool'
require_relative 'reviewer/version'

# Primary interface for the reviewer tools
module Reviewer
  class Error < StandardError; end

  class << self
    attr_writer :tags, :files, :keywords, :configuration, :logger

    def review
      perform(:review)
    end

    def format
      perform(:format)
    end

    def arguments
      @arguments ||= Arguments.new
    end

    def tags
      @tags ||= Arguments::Tags.new
    end

    def files
      @files ||= Arguments::Files.new
    end

    def keywords
      @keywords ||= Arguments::Keywords.new
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
        tool = Tool.new(key)

        next if tool.disabled?

        tools << tool
      end
      tools
    end

    private

    def perform(command_type)
      elapsed_time = Benchmark.realtime do
        tools.each do |tool|
          exit_status = Runner.new(tool, command_type).run

          break unless exit_status <= tool.max_exit_status
        end
      end
      puts "\n➤ Total Time: #{elapsed_time.round(3)}s\n"
    end
  end
end

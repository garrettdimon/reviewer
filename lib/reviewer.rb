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
    attr_writer :arguments, :configuration, :logger
  end

  def self.review
    elapsed_time = Benchmark.realtime do
      Tools.all.each do |tool|
        next if tool.disabled?

        exit_status = Runner.new(tool, :review).run

        break unless exit_status <= tool.max_exit_status
      end
    end
    puts "\n➤ Total Time: #{elapsed_time.round(3)}s\n"
  end

  def self.format
    Tools.all.each do |tool|
      Runner.run(tool, :format)
    end
  end

  def self.arguments
    @arguments ||= Arguments.new
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.reset
    @configuration = Configuration.new
    @arguments = Arguments.new
  end
end

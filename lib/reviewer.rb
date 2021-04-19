# frozen_string_literal: true

require "active_support/core_ext/string"

require_relative "reviewer/arguments"
require_relative "reviewer/configuration"
require_relative "reviewer/loader"
require_relative "reviewer/runner"
require_relative "reviewer/tool"
require_relative "reviewer/tools"
require_relative "reviewer/version"

module Reviewer
  class Error < StandardError; end

  class << self
    attr_writer :configuration
  end

  def self.review
    # options = Arguments.new
    total_time = 0
    Tools.all.each do |tool|
      next if tool.disabled?

      exit_status, elapsed_time = Runner.new(tool, :review).run

      break unless exit_status <= tool.max_exit_status

      total_time += elapsed_time
    end
  end

  def self.format
    # options = Arguments.new
    Tools.all.each do |tool|
      Runner.run(tool, :format)
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end

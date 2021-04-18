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
    options = Arguments.new
    Tools.all.each do |tool|
      Runner.run(tool, :review)
    end
  end

  def self.format
    options = Arguments.new
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

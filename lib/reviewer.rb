# frozen_string_literal: true

require_relative "reviewer/arguments"
require_relative "reviewer/configuration"
require_relative "reviewer/loader"
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
    # TODO: Make it actually run the tools.
    puts "Running with the following options:"
    pp options
  end

  def self.format
    options = Arguments.new
    # TODO: Make it actually run the tools.
    puts "Running with the following options:"
    pp options
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

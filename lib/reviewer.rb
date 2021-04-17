# frozen_string_literal: true

require_relative "reviewer/version"
require_relative "reviewer/configuration"

module Reviewer
  class Error < StandardError; end

  class << self
    attr_writer :configuration
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

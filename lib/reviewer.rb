# frozen_string_literal: true

require 'benchmark'
require 'forwardable'
# require 'logger'
require 'rainbow'

require_relative 'reviewer/configuration'
require_relative 'reviewer/configuration/loader'
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
    def reset! = @tools = @arguments = @prompt = nil

    # Runs the `review` command for the specified tools/files. Reviewer expects all configured
    #   commands that are not disabled to have an entry for the `review` command.
    #
    # @return [void] Prints output to the console
    def review
      return Setup.run if subcommand?(:init)
      return run_doctor if subcommand?(:doctor)
      return run_capabilities if capabilities_flag?

      exit build_session.review
    end

    # Runs the `format` command for the specified tools/files for which it is configured.
    #
    # @return [void] Prints output to the console
    def format
      return Setup.run if subcommand?(:init)
      return run_doctor if subcommand?(:doctor)
      return run_capabilities if capabilities_flag?

      exit build_session.format
    end

    # The collection of arguments that were passed via the command line.
    #
    # @return [Reviewer::Arguments] exposes tags, files, and keywords from arguments
    def arguments = @arguments ||= Arguments.new

    # An interface for the collection of configured tools for accessing subsets of tools
    #   based on enabled/disabled, tags, keywords, etc.
    #
    # @return [Reviewer::Tools] exposes the set of tools to be run in a given context
    def tools = @tools ||= Tools.new

    # The primary output method for Reviewer to consistently display success/failure details for a
    #   unique run of each tool and the collective summary when relevant.
    #
    # @return [Reviewer::Output] prints formatted output to the console.
    def output = @output ||= Output.new

    # A file store for sharing information across runs
    #
    # @return [Reviewer::History] a YAML::Store (or Pstore) containing data on tools
    def history = @history ||= History.new

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

    def subcommand?(name) = ARGV.first == name.to_s
    def capabilities_flag? = ARGV.include?('--capabilities') || ARGV.include?('-c')

    def run_capabilities
      puts Capabilities.new.to_json
    end

    def run_doctor
      report = Doctor.run
      Doctor::Formatter.new(output).print(report)
    end

    def build_session
      Session.new(
        arguments: arguments,
        tools: tools,
        output: output,
        history: history
      )
    end
  end
end

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
    # @param clear_screen [boolean] clears the screen to reduce noise when true
    #
    # @return [void] Prints output to the console
    def review(clear_screen: false)
      return Setup.run if subcommand?(:init)
      return run_doctor if subcommand?(:doctor)

      exit build_session.review(clear_screen: clear_screen)
    end

    # Runs the `format` command for the specified tools/files for which it is configured.
    # @param clear_screen [boolean] clears the screen to reduce noise when true
    #
    # @return [void] Prints output to the console
    def format(clear_screen: false)
      return Setup.run if subcommand?(:init)
      return run_doctor if subcommand?(:doctor)

      exit build_session.format(clear_screen: clear_screen)
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

    def run_doctor
      report = Doctor.run
      output.doctor_report(report)
    end

    def build_session
      Session.new(
        arguments: arguments,
        tools: tools,
        output: output,
        history: history,
        prompt: prompt,
        configuration: configuration
      )
    end
  end
end

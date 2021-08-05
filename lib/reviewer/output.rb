# frozen_string_literal: true

require 'colorize'

module Reviewer
  # Friendly API for printing nicely-formatted output to the console
  class Output
    SUCCESS = 'Success'
    FAILURE = 'Failure ·'
    DIVIDER = ('-' * 60).to_s

    attr_reader :printer

    def initialize(printer: Reviewer.configuration.printer)
      @printer = printer
    end

    def info(message)
      printer.info message
    end

    def blank_line
      printer.info
    end

    def divider
      blank_line
      printer.info DIVIDER.light_black
      blank_line
    end

    def tool_summary(tool)
      printer.info "\n#{tool.name}".bold + ' · '.light_black + tool.description
    end

    def current_command(command)
      command = String(command)

      printer.info "\nNow Running:"
      printer.info command.light_black
    end

    def exit_status(value)
      failure("Exit Status #{value}")
    end

    def success(timer)
      message = SUCCESS.green.bold + " #{timer.total_seconds}s".green
      message += " (#{timer.prep_percent}% preparation)".yellow if timer.prepped?

      printer.info message
    end

    def failure(details, command: nil)
      printer.error "#{FAILURE} #{details}".red.bold

      return if command.nil?

      blank_line
      printer.error 'Failed Command:'.red.bold
      printer.error String(command).light_black
    end

    def unrecoverable(details)
      printer.error 'Unrecoverable Error:'.red.bold
      printer.error details
    end

    def guidance(summary, details)
      return if details.nil?

      blank_line
      printer.info summary
      printer.info details.to_s.light_black
    end

    def missing_executable_guidance(command)
      tool = command.tool
      installation_command = Command.new(tool, :install, :no_silence).string if tool.installable?
      install_link = tool.install_link

      failure("Missing executable for '#{tool}'", command: command)
      guidance('Try installing the tool:', installation_command)
      guidance('Read the installation guidance:', install_link)
    end

    def syntax_guidance(ignore_link: nil, disable_link: nil)
      guidance('Selectively Ignore a Rule:', ignore_link)
      guidance('Fully Disable a Rule:', disable_link)
    end
  end
end

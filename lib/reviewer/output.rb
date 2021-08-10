# frozen_string_literal: true

module Reviewer
  # Friendly API for printing nicely-formatted output to the console
  class Output
    COLORS = {
      default: 39,
      red: 31,
      green: 32,
      yellow: 33,
      gray: 37,
      white: 97
    }.freeze

    WEIGHTS = { default: 0, bold: 1, light: 2 }.freeze

    DIVIDER = '-' * 60

    attr_reader :printer

    def initialize(printer: Reviewer.configuration.printer)
      @printer = printer
    end

    def help(message)
      line(:white) { message }
    end

    def batch_summary(tool_count, elapsed_time)
      newline
      text(:white, :bold) { "~#{elapsed_time.round(1)} seconds" }
      line(:white, :light) { " for #{tool_count} tools" }
    end

    def newline
      printer << "\n"
    end

    def divider
      newline
      line(:gray) { DIVIDER }
    end

    def tool_summary(tool)
      newline
      text(:white, :bold) { tool.name } & text(:white, :light) { " #{tool.description}" }
      newline
    end

    def current_command(command)
      command = String(command)

      newline
      line(:white, :bold) { 'Now Running:' }
      line(:gray) { String(command) }
    end

    def exit_status(value)
      failure("Exit Status #{value}")
    end

    def success(timer)
      text(:green, :bold) { 'Success' } & text(:green) { " #{timer.total_seconds}s" }
      text(:yellow) { " (#{timer.prep_percent}% prep ~#{timer.prep_seconds}s)" } if timer.prepped?
      newline
    end

    def failure(details, command: nil)
      text(:red, :bold) { 'Failure' } & text(:white, :light) { " #{details}" }
      newline

      return if command.nil?

      newline
      line(:white, :bold) { 'Failed Command:' }
      line(:gray) { String(command) }
    end

    def unrecoverable(details)
      line(:red, :bold) { 'Unrecoverable Error:' }
      line(:gray) { details }
    end

    def guidance(summary, details)
      return if details.nil?

      newline
      line(:white, :bold) { summary }
      line(:gray) { details }
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

    private

    def text(color = nil, weight = nil, &block)
      printer << "\e[#{style(color, weight)}m"
      printer << block.call
      printer << "\e[0m" # Reset
    end

    def line(color = nil, weight = nil, &block)
      text(color, weight) { block.call }
      newline
    end

    def style(color, weight)
      weight = WEIGHTS.fetch(weight) { WEIGHTS[:default] }
      color = COLORS.fetch(color) { COLORS[:default] }

      "#{weight};#{color}"
    end
  end
end

# frozen_string_literal: true

module Reviewer
  # Friendly API for printing nicely-formatted output to the console
  class Output
    COLORS = {
      default: 39,
      red:     31,
      green:   32,
      yellow:  33,
      gray:    37,
      white:   97
    }

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
      text(:white, :bold)  { "~#{elapsed_time.round(1)} seconds" }
      line(:white, :light) { " for #{tool_count} tools" }
    end

    def blank_line
      printer.<< "\n"
    end
    alias newline blank_line

    def divider
      blank_line
      line(:gray) { DIVIDER }
    end

    def tool_summary(tool)
      blank_line
      text(:white, :bold)  { tool.name }
      text(:white, :light) { " #{tool.description}" }
      newline
    end

    def current_command(command)
      command = String(command)

      blank_line
      line(:white, :bold) { 'Now Running:' }
      line(:gray) { String(command) }
    end

    def exit_status(value)
      failure("Exit Status #{value}")
    end

    def success(timer)
      text(:green, :bold)  { 'Success' }
      if timer.prepped?
        text(:green) { " #{timer.total_seconds}s" }
        text(:yellow)        { " (#{timer.prep_percent}% preparation ~#{timer.prep_seconds}s)" }
      else
        text(:white, :light) { " #{timer.total_seconds}s" }
      end
      newline
    end

    def failure(details, command: nil)
      text(:red, :bold)    { 'Failure' }
      text(:white, :light) { " #{details}" }
      newline

      return if command.nil?

      blank_line

      line(:white, :bold) { 'Failed Command:' }
      line(:gray) { String(command) }
    end

    def unrecoverable(details)
      line(:red, :bold) { 'Unrecoverable Error:' }
      line(:gray)       { details }
    end

    def guidance(summary, details)
      return if details.nil?

      blank_line
      line(:white, :bold) { summary }
      line(:gray)         { details }
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

    def text(color = nil, weight = nil)
      printer.<< "\e[#{weighted(weight)};#{colorized(color)}m"
      printer.<< yield
      printer.<< "\e[0m" # Reset
    end

    def line(color = nil, weight = nil)
      text(color, weight) { yield }
      newline
    end

    def colorized(value)
      COLORS.fetch(value) { COLORS[:default] }
    end

    def weighted(value)
      case value
      when :bold  then 1
      when :light then 2
      else             0
      end
    end
  end
end

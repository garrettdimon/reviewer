# frozen_string_literal: true

module Reviewer
  class Runner
    include Conversions

    class UnrecognizedCommandError < ArgumentError; end

    attr_reader :tool,
                :command_type,
                :verbosity,
                :shell,
                :output

    delegate :result,
             :run,
             to: :command

    delegate :result,
             :seed,
             :timer,
             to: :shell

    delegate :exit_status,
             :rerunnable?,
             to: :result

    def initialize(tool, command_type, verbosity)
      @tool         = Tool(tool)
      @command_type = command_type.to_sym
      @verbosity    = Verbosity(verbosity)
      @shell        = Shell.new
      @output       = Output.new
    end

    def success?
      result.success?(max_exit_status: tool.max_exit_status)
    end

    private

    def command
      @command ||= case command_type
                   when :install then Commands::Install.new(tool, verbosity)
                   when :prepare then Commands::Prepare.new(tool, verbosity)
                   when :review  then Commands::Review.new(tool, verbosity)
                   when :format  then Commands::Format.new(tool, verbosity)
                   else raise UnrecognizedCommandError, "'#{command_type}'"
                   end
    end

    def needs_prep?
      tool.prepare_command? && tool.stale?
    end

    def run_directly
      output.tool_summary(tool)

      output.current_command(command)
      output.divider

      # Using the shell here would capture the output as plain text and strip it of any color or
      # or special characters. So it runs the full command with no quiet optiosn directly in its
      # full glory and leaves the tool's own output formatting in tact
      shell.direct(command)

      output.divider
      output.last_command(command)

      show_guidance

      exit_status
    end

    def show_current_tool
      output.tool_summary(tool)
    end

    def show_result
      if success?
        output.success(timer)
      else
        output.failure("Exit Status #{exit_status} · #{result}")
        show_guidance
      end
    end

    def show_guidance
      if result.executable_not_found?
        show_missing_executable_guidance
      elsif result.cannot_execute?
        show_unrecoverable_guidance
      else
        show_syntax_guidance
      end
    end

    def show_missing_executable_guidance
      return unless result.executable_not_found?

      output.missing_executable_guidance(tool: tool, command: shell.command)
    end

    def show_unrecoverable_guidance
      output.unrecoverable(result.stderr)
    end

    def show_syntax_guidance
      output.syntax_guidance(
        ignore_link: tool.settings.links[:ignore_syntax],
        disable_link: tool.settings.links[:disable_syntax]
      )
    end
  end
end

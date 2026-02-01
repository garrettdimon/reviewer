# frozen_string_literal: true

module Reviewer
  class Runner
    # Handles the logic around what to display after a command has been run
    class Guidance
      attr_reader :command, :result, :output

      # Create an instance of guidance for suggesting recovery steps after errors
      # @param command: [Command] the command that was run and needs recovery guidance
      # @param result: [Result] the result of the command
      # @param output: Reviewer.output [Output] the output channel for displaying content
      #
      # @return [Guidance] the guidance class to suggest relevant recovery steps
      def initialize(command:, result:, output: Reviewer.output)
        @command = command
        @result = result
        @output = output
      end

      # Prints the relevant guidance based on the command and result context
      #
      # @return [void] prints the relevant guidance to the stream
      def show
        case result
        when executable_not_found? then show_missing_executable_guidance
        when cannot_execute?       then show_unrecoverable_guidance
        else                            show_syntax_guidance
        end
      end

      private

      # Conditional check for when the command result was that the executable couldn't be found
      #
      # @return [Boolean] true if the result indicates the command couldn't be found
      def executable_not_found?
        lambda(&:executable_not_found?)
      end

      # Conditional check for when the command result was that it was unable to be executed
      #
      # @return [Boolean] true if the result indicates the command couldn't be executed
      def cannot_execute?
        lambda(&:cannot_execute?)
      end

      # Shows the recovery guidance for when a command is missing
      #
      # @return [void] prints missing executable guidance
      def show_missing_executable_guidance
        tool = command.tool
        installation_command = Command.new(tool, :install).string if tool.installable?
        install_link = tool.install_link

        output.failure("Missing executable for '#{tool}'", command: command)
        output.guidance('Try installing the tool:', installation_command)
        output.guidance('Read the installation guidance:', install_link)
      end

      # Shows the recovery guidance for when a command generates an unrecoverable error
      #
      # @return [void] prints unrecoverable error guidance
      def show_unrecoverable_guidance
        output.unrecoverable(result.stderr)
      end

      # Shows suggestions for ignoring or disable rules when a command fails after reviewing code
      #
      # @return [void] prints syntax guidance
      def show_syntax_guidance
        output.guidance('Selectively Ignore a Rule:', command.tool.links[:ignore_syntax])
        output.guidance('Fully Disable a Rule:', command.tool.links[:disable_syntax])
      end
    end
  end
end

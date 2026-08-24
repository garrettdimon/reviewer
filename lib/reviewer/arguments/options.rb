# frozen_string_literal: true

module Reviewer
  class Arguments
    # Defines the command-line flags `rvw` and `fmt` accept.
    #
    # This is the single place the flag vocabulary is declared. It holds no
    # state -- it configures a Slop parser and nothing else -- which is why it
    # lives here rather than on Arguments, whose job is answering questions
    # about what was parsed.
    module Options
      module_function

      # Declares every flag on the given Slop parser
      # @param opts [Slop::Options] the parser being configured
      #
      # @return [void]
      def configure(opts)
        input(opts)
        output(opts)
        info(opts)
      end

      # Flags that narrow what gets reviewed
      # @param opts [Slop::Options] the parser being configured
      #
      # @return [void]
      def input(opts)
        opts.array '-f', '--files', 'a list of comma-separated files or paths', delimiter: ',', default: []
        opts.array '-t', '--tags', 'a list of comma-separated tags', delimiter: ',', default: []
      end

      # Flags that select how results are displayed
      # @param opts [Slop::Options] the parser being configured
      #
      # @return [void]
      def output(opts)
        opts.on '-r', '--raw', 'force raw output (no capturing)'
        opts.on '-j', '--json', 'output results as JSON'
        opts.string '--format', 'output format (streaming, summary, json)', default: 'streaming'
      end

      # Flags that report on Reviewer itself and exit early
      # @param opts [Slop::Options] the parser being configured
      #
      # @return [void]
      def info(opts)
        opts.on '-v', '--version', 'print the version'
        opts.on '-h', '--help', 'print the help'
        opts.on '-c', '--capabilities', 'output capabilities as JSON'
      end
    end
  end
end

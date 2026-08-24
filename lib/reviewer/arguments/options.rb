# frozen_string_literal: true

module Reviewer
  class Arguments
    # Defines the command-line flags `rvw` and `fmt` accept.
    #
    # Separate from Arguments because declaring what can be parsed and answering
    # questions about what was parsed are different jobs, and only the second
    # one needs instance state.
    module Options
      module_function

      # Declares every flag on the given Slop parser
      # @param opts [Slop::Options] the parser being configured
      #
      # @return [void]
      # :reek:TooManyStatements -- a flag declaration list, not branching logic
      def configure(opts)
        # Narrowing what gets reviewed
        opts.array '-f', '--files', 'a list of comma-separated files or paths', delimiter: ',', default: []
        opts.array '-t', '--tags', 'a list of comma-separated tags', delimiter: ',', default: []

        # Selecting how results are displayed
        opts.on '-r', '--raw', 'force raw output (no capturing)'
        opts.on '-j', '--json', 'output results as JSON'
        opts.string '--format', 'output format (streaming, summary, json)', default: 'streaming'

        # Reporting on Reviewer itself, then exiting early
        opts.on '-v', '--version', 'print the version'
        opts.on '-h', '--help', 'print the help'
        opts.on '-c', '--capabilities', 'output capabilities as JSON'
      end
    end
  end
end

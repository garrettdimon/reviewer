# frozen_string_literal: true

require 'slop'

require_relative 'arguments/keywords'
require_relative 'arguments/files'
require_relative 'arguments/tags'

module Reviewer
  # Handles option parsing for `rvw` and `fmt` commands
  #
  # @example
  #
  #   `rvw`
  #   `rvw -t ruby`
  #   `rvw -f ./example.rb,./example_test.rb`
  #   `rvw staged`
  #   `rvw --files ./example.rb,./example_test.rb --tags syntax`
  #   `rvw ruby staged`
  #
  class Arguments
    attr_accessor :options

    attr_reader :output

    # A catch all for aguments passed to reviewer via the command-line so they can be interpreted
    #   and made available via the relevant classes.
    # @param options = ARGV [Hash] options to parse and extract the relevant values for a run
    #
    # @example Using all options: `rvw keyword_one keyword_two --files ./example.rb,./example_test.rb --tags syntax`
    #   reviewer = Reviewer::Arguments.new
    #   reviewer.files.to_a # => ['./example.rb','./example_test.rb']
    #   reviewer.tags.to_a # => ['syntax']
    #   reviewer.keywords.to_a # => ['keyword_one', 'keyword_two']
    #
    # @return [self]
    def initialize(options = ARGV)
      @output = Output.new
      @options = Slop.parse(options) { |opts| configure_options(opts) }
    end

    private

    def configure_options(opts)
      configure_input_options(opts)
      configure_output_options(opts)
      configure_info_options(opts)
    end

    def configure_input_options(opts)
      opts.array '-f', '--files', 'a list of comma-separated files or paths', delimiter: ',', default: []
      opts.array '-t', '--tags', 'a list of comma-separated tags', delimiter: ',', default: []
    end

    def configure_output_options(opts)
      opts.on '-r', '--raw', 'force raw output (no capturing)'
      opts.on '-j', '--json', 'output results as JSON'
      opts.string '--format', 'output format (streaming, summary, json)', default: 'streaming'
    end

    def configure_info_options(opts)
      opts.on('-v', '--version', 'print the version') { @output.help(VERSION) && exit }
      opts.on('-h', '--help', 'print the help') { @output.help(opts) && exit }
    end

    public

    # Converts the arguments to a hash for versatility
    #
    # @return [Hash] The files, tags, and keywords collected from the command line options
    def to_h
      {
        files: files.raw,
        tags: tags.raw,
        keywords: keywords.raw
      }
    end
    alias inspect to_h

    # The tag arguments collected from the command line via the `-t` or `--tags` flag
    #
    # @return [Arguments::Tags] an colelction of the tag arguments collected from the command-line
    def tags = @tags ||= Arguments::Tags.new(provided: options[:tags])

    # The file arguments collected from the command line via the `-f` or `--files` flag
    #
    # @return [Arguments::Files] an collection of the file arguments collected from the command-line
    def files = @files ||= Arguments::Files.new(provided: options[:files])

    # The leftover arguments collected from the command line without being associated with a flag
    #
    # @return [Arguments::Keywords] an collection of the leftover arguments as keywords
    def keywords = @keywords ||= Arguments::Keywords.new(options.arguments)

    # Whether to force raw/passthrough output regardless of tool count
    #
    # @return [Boolean] true if raw output mode is requested
    def raw? = options[:raw]

    # Whether to output results as JSON
    #
    # @return [Boolean] true if JSON output mode is requested
    def json? = options[:json]

    # The output format for results
    #
    # @return [Symbol] the output format (:streaming, :summary, or :json)
    def format
      return :json if json?

      options[:format].to_sym
    end
  end
end

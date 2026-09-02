# frozen_string_literal: true

require 'slop'

require_relative 'arguments/options'
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
    # Valid output format options for the --format flag
    KNOWN_FORMATS = %i[streaming summary json].freeze

    # @!attribute options
    #   @return [Slop::Result] the parsed command-line options
    attr_reader :options

    attr_reader :output

    # Parses command-line arguments and makes them available as tags, files, and keywords.
    # @param options [Array<String>] the command-line arguments to parse (defaults to ARGV)
    # @param output [Output] the console output handler for displaying messages
    #
    # @example Using all options: `rvw keyword_one keyword_two --files ./example.rb,./example_test.rb --tags syntax`
    #   reviewer = Reviewer::Arguments.new
    #   reviewer.files.to_a # => ['./example.rb','./example_test.rb']
    #   reviewer.tags.to_a # => ['syntax']
    #   reviewer.keywords.to_a # => ['keyword_one', 'keyword_two']
    #
    # @return [self]
    def initialize(options = ARGV, output: Output.new)
      @output = output
      @raw_options = options.to_a.dup
      @invalid_files_option = false
      previous_file_count = 0
      files_callback = lambda do |files|
        file_count = Array(files).length
        @invalid_files_option = true if file_count <= previous_file_count
        previous_file_count = file_count
      end
      @parser = Slop::Options.new
      Options.configure(@parser, files_callback: files_callback)
      @options = @parser.parse(options)
    end

    private

    def session_formatter = @session_formatter ||= Session::Formatter.new(output)

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
    # @return [Arguments::Tags] a collection of the tag arguments collected from the command-line
    def tags = @tags ||= Arguments::Tags.new(provided: options[:tags])

    # The file arguments collected from the command line via the `-f` or `--files` flag
    #
    # @return [Arguments::Files] a collection of the file arguments collected from the command-line
    def files
      @files ||= Arguments::Files.new(
        provided: options[:files],
        keywords: keywords.for_files,
        output: output,
        on_git_error: session_formatter.method(:git_error)
      )
    end

    # The leftover arguments collected from the command line without being associated with a flag
    #
    # @return [Arguments::Keywords] a collection of the leftover arguments as keywords
    def keywords = @keywords ||= Arguments::Keywords.new(options.arguments)

    # Whether the --help flag was passed
    #
    # @return [Boolean] true if help was requested
    def help? = options[:help]

    # Whether the --version flag was passed
    #
    # @return [Boolean] true if version was requested
    def version? = options[:version]

    # Whether to force raw/passthrough output regardless of tool count
    #
    # @return [Boolean] true if raw output mode is requested
    def raw? = options[:raw]

    # Whether to output results as JSON
    #
    # @return [Boolean] true if JSON output mode is requested
    def json?
      return options[:json] unless invalid_files_option?

      options[:json] || raw_option_tokens.any? { |token| json_option_token?(token) }
    end

    # Whether a files option was supplied without a usable value
    #
    # @return [Boolean] true when any -f/--files occurrence is empty
    def invalid_files_option?
      @invalid_files_option || raw_option_tokens.each_index.any? do |index|
        files_option_awaiting_value?(raw_option_tokens[index]) &&
          known_option_token?(raw_option_tokens[index + 1])
      end
    end

    # The output format for results
    #
    # @return [Symbol] the output format (:streaming, :summary, or :json)
    def format
      return :json if json?

      raw_value = invalid_files_option? ? recovered_format || options[:format] : options[:format]
      value = raw_value.to_sym
      return value if KNOWN_FORMATS.include?(value)

      session_formatter.invalid_format(raw_value, KNOWN_FORMATS)
      :streaming
    end

    # Whether output should be streamed directly (not captured for later formatting)
    #
    # @return [Boolean] true if in streaming mode
    def streaming? = format == :streaming

    # Determines the appropriate runner strategy based on CLI flags
    #
    # @param multiple_tools [Boolean] whether multiple tools are being run
    # @return [Class] the strategy class (Captured or Passthrough)
    def runner_strategy(multiple_tools:)
      return Runner::Strategies::Passthrough if raw?
      return Runner::Strategies::Captured unless streaming?

      multiple_tools ? Runner::Strategies::Captured : Runner::Strategies::Passthrough
    end

    private

    def raw_option_tokens = @raw_option_tokens ||= @raw_options.take_while { |token| token != '--' }

    def known_option_token?(token)
      return false unless token&.start_with?('-')

      exact_option_token?(token) || long_option_token?(token) || short_option_token?(token)
    end

    def exact_option_token?(token) = parser_options.any? { |option| option.flags.include?(token) }

    def long_option_token?(token)
      parser_options.any? do |option|
        option.flags.any? { |flag| flag.start_with?('--') && token.start_with?("#{flag}=") }
      end
    end

    def short_option_token?(token)
      return false unless token.match?(/\A-[^-]{2,}\z/)

      first = parser_options.find { |option| option.flags.include?(token[0, 2]) }
      return true if first&.expects_argument?

      token.delete_prefix('-').chars.all? { |character| short_flags.include?("-#{character}") }
    end

    def parser_options = @parser_options ||= @parser.to_a
    def short_flags = @short_flags ||= parser_options.flat_map(&:flags).grep(/\A-[^-]\z/)

    def files_option_awaiting_value?(token)
      return true if %w[-f --files].include?(token)

      token.match?(/\A-[^-]+f\z/) && short_option_token?(token)
    end

    def json_option_token?(token)
      return true if %w[-j --json].include?(token)

      token.match?(/\A-[^-]{2,}\z/) && short_option_token?(token) && token.include?('j')
    end

    def recovered_format
      raw_option_tokens.each_with_index.filter_map do |option, index|
        if option == '--format'
          raw_option_tokens[index + 1]
        elsif option.start_with?('--format=')
          option.split('=', 2).last
        end
      end
                       .last
    end
  end
end

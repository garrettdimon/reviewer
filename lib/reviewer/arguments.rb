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
      @parser = Slop::Options.new
      Options.configure(@parser, files_callback: files_validation_callback)
      @options = @parser.parse(normalized_options)
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
    def json? = options[:json]

    # Whether the --capabilities flag was passed
    #
    # @return [Boolean] true if capabilities were requested
    def capabilities? = options[:capabilities]

    # Whether a files option was supplied without a usable value
    #
    # @return [Boolean] true when any -f/--files occurrence is empty
    def invalid_files_option? = @invalid_files_option

    # The output format for results
    #
    # @return [Symbol] the output format (:streaming, :summary, or :json)
    def format
      return :json if json?

      value = options[:format].to_sym
      return value if KNOWN_FORMATS.include?(value)

      session_formatter.invalid_format(options[:format], KNOWN_FORMATS) unless invalid_files_option?
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

    def files_validation_callback
      previous_file_count = 0
      lambda do |files|
        current_files = Array(files)
        file_count = current_files.length
        new_files = current_files.drop(previous_file_count)
        @invalid_files_option = true if file_count <= previous_file_count ||
                                        new_files.all? { |file| file.strip.empty? }
        previous_file_count = file_count
      end
    end

    def normalized_options
      parsing_options = true
      @raw_options.each_with_index.flat_map do |token, index|
        parsing_options = false if token == '--'
        missing_value = parsing_options && files_option_awaiting_value?(token) &&
                        known_option_token?(@raw_options[index + 1])
        normalized_token = parsing_options ? normalize_compact_files_option(token) : token

        missing_value ? [normalized_token, ''] : [normalized_token]
      end
    end

    def normalize_compact_files_option(token)
      return token unless token.start_with?('-f') && token.length > 2 && !token.start_with?('-f=')

      "-f=#{token.delete_prefix('-f')}"
    end

    def known_option_token?(token)
      return false unless token&.start_with?('-') && token != '--'

      Slop.parse([token]) { |opts| Options.configure(opts) }
      true
    rescue Slop::UnknownOption
      false
    end

    def files_option_awaiting_value?(token)
      return true if %w[-f --files].include?(token)
      return false if token.start_with?('-f')

      token.match?(/\A-[^-]+f\z/) && known_option_token?(token)
    end
  end
end

# frozen_string_literal: true

require_relative 'arguments/keywords'
require_relative 'arguments/files'
require_relative 'arguments/tags'

require 'slop'

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

   # A catch all for aguments passed to reviewer via the command-line.
   # @param options = ARGV [Hash] options to parse and extract the relevant values for a run
   #
   # @return [Reviewer::Arguments] the full collection of arguments provided via the command line
   def initialize(options = ARGV)
      @output = Output.new
      @options = Slop.parse options do |opts|
        opts.array '-f', '--files', 'a list of comma-separated files or paths', delimiter: ',', default: []
        opts.array '-t', '--tags', 'a list of comma-separated tags', delimiter: ',', default: []

        opts.on '-v', '--version', 'print the version' do
          @output.info VERSION
          exit
        end

        opts.on '-h', '--help', 'print the help' do
          @output.info opts
          exit
        end
      end
    end

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
    def tags
      @tags ||= Arguments::Tags.new(provided: options[:tags])
    end

    # The file arguments collected from the command line via the `-f` or `--files` flag
    #
    # @return [Arguments::Files] an collection of the file arguments collected from the command-line
    def files
      @files ||= Arguments::Files.new(provided: options[:files])
    end

    # The leftover arguments collected from the command line without being associated with a flag
    #
    # @return [Arguments::Keywords] an collection of the leftover arguments as keywords
    def keywords
      @keywords ||= Arguments::Keywords.new(options.arguments)
    end
  end
end

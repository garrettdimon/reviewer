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
  #   `rvw staged`
  #   `rvw --files ./example.rb,./example_test.rb --tags syntax`
  #   `rvw ruby staged`
  #
  class Arguments
    attr_accessor :options

    def initialize(options = ARGV)
      @options = Slop.parse options do |opts|
        opts.array '-f', '--files', 'a list of comma-separated files or paths', delimiter: ',', default: []
        opts.array '-t', '--tags', 'a list of comma-separated tags', delimiter: ',', default: []

        opts.on '-v', '--version', 'print the version' do
          puts VERSION
          exit
        end

        opts.on '-h', '--help', 'print the help' do
          puts opts
          exit
        end
      end
    end

    def inspect
      {
        files: files.raw,
        tags: tags.raw,
        keywords: keywords.raw
      }
    end

    def tags
      @tags ||= Arguments::Tags.new(provided: options[:tags])
    end

    def files
      @files ||= Arguments::Files.new(provided: options[:files])
    end

    def keywords
      @keywords ||= Arguments::Keywords.new(options.arguments)
    end

    def tool_names
      @tool_names ||= keywords.for_tool_names.to_a
    end
  end
end

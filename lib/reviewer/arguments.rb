# frozen_string_literal: true

require 'slop'

module Reviewer
  # Handles option parsing for `rvw` and `fmt` commands
  class Arguments
    KEYWORDS = %w[new staged].freeze

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

    def files
      options[:files]
    end

    def tags
      options[:tags]
    end

    def arguments
      options.arguments
    end

    def keywords
      arguments.reject { |arg| unrecognized_keyword?(arg) }
    end

    private

    def unrecognized_keyword?(arg)
      !KEYWORDS.include?(arg)
    end
  end
end

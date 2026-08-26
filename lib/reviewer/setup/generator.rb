# frozen_string_literal: true

require 'yaml'

require_relative 'tool_block'

module Reviewer
  module Setup
    # Produces .reviewer.yml YAML content from a list of detected tool keys.
    # Orchestrates which tools to include; delegates per-tool rendering to ToolBlock.
    class Generator
      attr_reader :tool_keys

      # Creates a generator for producing .reviewer.yml configuration
      # @param tool_keys [Array<Symbol>] catalog tool keys to include in config
      #
      # @return [Generator]
      def initialize(tool_keys)
        @tool_keys = tool_keys
      end

      # Generates YAML configuration string for the detected tools
      #
      # @return [String] valid YAML for .reviewer.yml
      def generate
        return "--- {}\n" if tool_keys.empty?

        blocks = tool_keys.filter_map do |key|
          definition = Catalog.config_for(key)
          next unless definition

          ToolBlock.new(key, definition).to_s
        end

        "---\n#{blocks.join("\n")}"
      end
    end
  end
end

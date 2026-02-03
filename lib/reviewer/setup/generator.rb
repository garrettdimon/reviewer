# frozen_string_literal: true

require 'yaml'

require_relative 'tool_block'

module Reviewer
  module Setup
    # Produces .reviewer.yml YAML content from a list of detected tool keys.
    # Orchestrates which tools to include; delegates per-tool rendering to ToolBlock.
    class Generator
      attr_reader :tool_keys, :project_dir

      # Creates a generator for producing .reviewer.yml configuration
      # @param tool_keys [Array<Symbol>] catalog tool keys to include in config
      # @param project_dir [Pathname] the project root (used for package manager detection)
      #
      # @return [Generator]
      def initialize(tool_keys, project_dir: Pathname.pwd)
        @tool_keys = tool_keys
        @project_dir = Pathname(project_dir)
      end

      # Generates YAML configuration string for the detected tools
      #
      # @return [String] valid YAML for .reviewer.yml
      def generate
        return "--- {}\n" if tool_keys.empty?

        blocks = tool_keys.filter_map do |key|
          definition = Catalog.config_for(key)
          next unless definition

          ToolBlock.new(key, definition, js_runner: js_runner).to_s
        end

        "---\n#{blocks.join("\n")}"
      end

      private

      # Detects the JS package manager based on lockfile presence
      def js_runner
        @js_runner ||= if project_dir.join('yarn.lock').exist?
                         'yarn'
                       elsif project_dir.join('pnpm-lock.yaml').exist?
                         'pnpm exec'
                       else
                         'npx'
                       end
      end
    end
  end
end

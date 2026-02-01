# frozen_string_literal: true

require 'yaml'

module Reviewer
  module Setup
    # Produces .reviewer.yml YAML content from a list of detected tool keys.
    # Builds commented YAML strings and adjusts JS commands for the detected package manager.
    class Generator
      attr_reader :tool_keys, :project_dir

      # @param tool_keys [Array<Symbol>] catalog tool keys to include in config
      # @param project_dir [Pathname] the project root (used for package manager detection)
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

          tool_block(key, definition)
        end

        "---\n#{blocks.join("\n")}"
      end

      # YAML values that must be quoted to avoid being parsed as booleans or null
      YAML_BARE_WORDS = %w[true false yes no on off null ~].freeze

      private

      def tool_block(key, definition)
        lines = header_lines(key, definition)
        lines.concat(commands_block(definition[:commands]))
        lines.concat(files_block(definition[:files])) if definition[:files]
        lines << ''
        lines.join("\n")
      end

      def header_lines(key, definition)
        lines = []
        lines << "# #{definition[:description]}"
        lines << "#{key}:"
        lines << "  name: #{quote(definition[:name])}"
        lines << "  description: #{quote(definition[:description])}"
        lines << tags_line(definition[:tags]) if definition[:tags]&.any?
        lines
      end

      def tags_line(tags)
        "  tags: [#{tags.join(', ')}]"
      end

      def commands_block(commands)
        lines = ['  commands:']
        %i[install prepare review format].each do |type|
          next unless commands[type]

          lines << "    #{type}: #{quote(apply_js_runner(commands[type].to_s))}"
        end
        lines
      end

      def files_block(files)
        lines = ['  files:']
        lines.concat(files_command_lines(files))
        lines.concat(files_targeting_lines(files))
        lines
      end

      def files_command_lines(files)
        %i[review format].filter_map do |type|
          "    #{type}: #{quote(apply_js_runner(files[type].to_s))}" if files[type]
        end
      end

      def files_targeting_lines(files)
        lines = []
        lines << "    flag: #{quote(files[:flag])}" if files.key?(:flag)
        lines << "    separator: #{quote(files[:separator])}" if files.key?(:separator)
        lines << "    pattern: #{quote(files[:pattern])}" if files[:pattern]
        lines << "    map_to_tests: #{files[:map_to_tests]}" if files[:map_to_tests]
        lines
      end

      def quote(value)
        return "''" if value.nil? || (value.is_a?(String) && value.empty?)

        str = value.to_s
        needs_quoting?(str) ? "'#{str.gsub("'", "''")}'" : str
      end

      def needs_quoting?(str)
        str.match?(/[:#\[\]{}&*!|>'"@`,]/) ||
          str.strip != str ||
          str.empty? ||
          YAML_BARE_WORDS.include?(str.downcase)
      end

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

      # Substitutes npx with the detected JS runner
      def apply_js_runner(command)
        return command unless command.start_with?('npx ')

        command.sub('npx ', "#{js_runner} ")
      end
    end
  end
end

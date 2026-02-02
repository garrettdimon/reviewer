# frozen_string_literal: true

module Reviewer
  module Setup
    # Renders the YAML configuration block for a single tool definition.
    # Owns the definition data so rendering methods reference self's state
    # rather than reaching into parameters.
    class ToolBlock
      YAML_BARE_WORDS = %w[true false yes no on off null ~].freeze

      # Creates a renderer for a single tool's YAML configuration block
      # @param key [Symbol] the tool key (e.g., :rubocop)
      # @param definition [Hash] the catalog definition for this tool
      # @param js_runner [String] the JS package runner to substitute for npx
      #
      # @return [ToolBlock]
      def initialize(key, definition, js_runner:)
        @key = key
        @definition = definition
        @js_runner = js_runner
      end

      # Renders the full YAML block for this tool
      #
      # @return [String] the YAML text for this tool's configuration
      def to_s
        lines = header_lines
        lines.concat(commands_block)
        lines.concat(files_block) if @definition[:files]
        lines << ''
        lines.join("\n")
      end

      private

      def header_lines
        lines = []
        lines << "# #{@definition[:description]}"
        lines << "#{@key}:"
        lines << "  name: #{quote(@definition[:name])}"
        lines << "  description: #{quote(@definition[:description])}"
        lines << tags_line if @definition[:tags]&.any?
        lines
      end

      def tags_line
        "  tags: [#{@definition[:tags].join(', ')}]"
      end

      def commands_block
        commands = @definition[:commands]
        lines = ['  commands:']
        %i[install prepare review format].each do |type|
          next unless commands[type]

          lines << "    #{type}: #{quote(apply_js_runner(commands[type].to_s))}"
        end
        lines
      end

      def files_block
        lines = ['  files:']
        lines.concat(files_command_lines)
        lines.concat(files_targeting_lines)
        lines
      end

      def files_command_lines
        %i[review format].filter_map do |type|
          "    #{type}: #{quote(apply_js_runner(tool_files[type].to_s))}" if tool_files[type]
        end
      end

      def files_targeting_lines
        [
          (file_setting_line(:flag) if tool_files.key?(:flag)),
          (file_setting_line(:separator) if tool_files.key?(:separator)),
          (file_setting_line(:pattern) if tool_files[:pattern]),
          ("    map_to_tests: #{tool_files[:map_to_tests]}" if tool_files[:map_to_tests])
        ].compact
      end

      def file_setting_line(key)
        "    #{key}: #{quote(tool_files[key])}"
      end

      def tool_files
        @definition[:files]
      end

      def apply_js_runner(command)
        return command unless command.start_with?('npx ')

        command.sub('npx ', "#{@js_runner} ")
      end

      def quote(value)
        str = value.to_s
        return "''" if str.empty?

        needs_quoting?(str) ? "'#{str.gsub("'", "''")}'" : str
      end

      def needs_quoting?(str)
        str.match?(/[:#\[\]{}&*!|>'"@`,]/) ||
          str.strip != str ||
          str.empty? ||
          YAML_BARE_WORDS.include?(str.downcase)
      end
    end
  end
end

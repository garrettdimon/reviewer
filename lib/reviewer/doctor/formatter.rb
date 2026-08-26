# frozen_string_literal: true

require_relative '../output/formatting'

module Reviewer
  module Doctor
    # Display logic for diagnostic reports
    class Formatter
      include Output::Formatting

      attr_reader :output, :printer
      private :output, :printer

      SYMBOLS = { ok: "\u2713", warning: '!', error: "\u2717", info: "\u00b7" }.freeze
      STYLES = { ok: :success, warning: :warning, error: :failure, info: :muted }.freeze
      COMMAND_LABELS = {
        review: 'Review',
        format: 'Format',
        prepare: 'Prepare',
        install: 'Install'
      }.freeze
      CONFIGURATION_STATES = {
        valid: [:success, "\u2713", 'is valid'],
        missing: [:muted, "\u00b7", 'not found'],
        invalid: [:failure, "\u2717", 'is invalid']
      }.freeze
      LABEL_WIDTH = 15

      # Creates a formatter for diagnostic report display
      # @param output [Output] the console output handler
      #
      # @return [Formatter]
      def initialize(output)
        @output = output
        @printer = output.printer
      end

      # Renders a full diagnostic report
      # @param report [Doctor::Report] the report to display
      def print(report)
        print_header
        print_sections(report)
        print_summary(report)
      end

      private

      def print_header
        output.newline
        printer.puts(:bold, 'Reviewer Doctor')
        output.newline
      end

      def print_sections(report)
        print_configuration(report)
        print_configured_tools(report.configured_tools) if report.configured_tools.any?
        print_discoveries(report.discoveries) if report.discoveries.any?
        print_environment(report.environment) if report.environment.any?
      end

      def print_configuration(report)
        printer.puts(:bold, 'Configuration')
        print_configuration_state(report)
        report.section(:configuration).each { |finding| print_finding(finding) }
        output.newline
      end

      def print_configuration_state(report)
        style, symbol, description = CONFIGURATION_STATES.fetch(report.configuration_state, [])
        return unless style

        printer.puts(style, "  #{symbol} #{report.configuration_path} #{description}")
      end

      def print_configured_tools(tools)
        printer.puts(:bold, 'Configured tools')
        tools.each { |tool| print_configured_tool(tool) }
        output.newline
      end

      def print_configured_tool(tool)
        suffix = tool.skip_in_batch ? ' — skipped in batch' : ''
        printer.puts(:default, "  #{tool.name} (#{tool.key})#{suffix}")
        tool.commands.each { |type, command| print_labeled(COMMAND_LABELS.fetch(type), command) }
        print_files(tool.files) if tool.files.any?
        print_labeled('Configured in', format_source(tool.source))
      end

      def print_files(files)
        value = files[:pattern]
        value = "#{value} \u2192 #{files[:map_to_tests]}" if value && files[:map_to_tests]
        print_labeled('Files', value) if value
      end

      def print_discoveries(discoveries)
        printer.puts(:bold, 'Discoveries')
        discoveries.each do |discovery|
          printer.puts(:default, "  #{discovery.name}")
          discovery.observations.select { |observation| observation.kind == :command }.each do |observation|
            print_labeled('Command', observation.value)
          end
          print_sources(discovery.observations)
        end
        output.newline
      end

      def print_sources(observations)
        observations.each_with_index do |observation, index|
          label = index.zero? ? 'Discovered via' : ''
          print_labeled(label, format_source(path: observation.path, location: observation.location))
        end
      end

      def print_environment(environment)
        printer.puts(:bold, 'Environment')
        if environment.all? { |finding| finding.status == :ok }
          values = environment.map { |finding| environment_value(finding) }
          printer.puts(:success, "  \u2713 #{values.join(" \u00b7 ")}")
        else
          environment.each { |finding| print_environment_finding(finding) }
        end
        output.newline
      end

      def environment_value(finding)
        return "Ruby #{finding.value}" if finding.name == :ruby
        return "git #{finding.value}" if finding.name == :git

        finding.value
      end

      def print_environment_finding(finding)
        print_finding(Report::Finding.new(
                        status: finding.status,
                        message: environment_value(finding),
                        detail: finding.detail
                      ))
      end

      def print_finding(finding)
        symbol = SYMBOLS.fetch(finding.status) { ' ' }
        style = STYLES.fetch(finding.status) { :default }

        printer.print(style, "  #{symbol} ")
        printer.puts(:default, finding.message)
        printer.puts(:muted, "    #{finding.detail}") if finding.detail
      end

      def print_labeled(label, value)
        printer.puts(:default, "    #{label.ljust(LABEL_WIDTH)}#{value}")
      end

      def format_source(source)
        [source.fetch(:path), source[:location]].compact.join(" \u203a ")
      end

      def print_summary(report)
        text = if report.configuration_state == :missing
                 "No tools configured \u00b7 #{report.discoveries.size} discovered"
               else
                 "Configuration #{report.configuration_state} \u00b7 " \
                   "#{report.configured_tools.size} configured \u00b7 #{report.discoveries.size} discovered"
               end
        printer.puts(report.configuration_state == :invalid ? :failure : :success, text)
        output.newline
      end
    end
  end
end

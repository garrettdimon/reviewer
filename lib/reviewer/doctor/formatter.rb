# frozen_string_literal: true

require_relative '../output/formatting'

module Reviewer
  module Doctor
    # Display logic for diagnostic reports
    class Formatter
      include Output::Formatting

      SYMBOLS = { ok: "\u2713", warning: '!', error: "\u2717", info: "\u00b7", muted: "\u00b7" }.freeze
      STYLES  = { ok: :success, warning: :warning, error: :failure, info: :muted, muted: :muted }.freeze

      SECTION_LABELS = {
        configuration: 'Configuration',
        tools: 'Tools',
        opportunities: 'Opportunities',
        environment: 'Environment'
      }.freeze

      def initialize(output)
        @output = output
        @printer = output.printer
      end

      # Renders a full diagnostic report
      # @param report [Doctor::Report] the report to display
      def print(report)
        @output.newline
        Doctor::Report::SECTIONS.each do |section|
          findings = report.section(section)
          print_section(section, findings) if findings.any?
        end
        print_summary(report)
      end

      private

      def print_section(section, findings)
        @printer.puts(:bold, SECTION_LABELS.fetch(section, section.to_s.capitalize))
        findings.each { |finding| print_finding(finding) }
        @output.newline
      end

      def print_finding(finding)
        symbol = SYMBOLS.fetch(finding.status, ' ')
        style = STYLES.fetch(finding.status, :default)

        @printer.print(style, "  #{symbol} ")
        @printer.puts(:default, finding.message)
        @printer.puts(:muted, "    #{finding.detail}") if finding.detail
      end

      def print_summary(report)
        if report.ok?
          @printer.puts(:success, 'No issues found')
        else
          @printer.puts(:failure, pluralize(report.errors.size, 'issue found', 'issues found'))
        end
        @output.newline
      end
    end
  end
end

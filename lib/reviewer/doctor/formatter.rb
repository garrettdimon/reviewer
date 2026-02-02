# frozen_string_literal: true

require_relative '../output/formatting'

module Reviewer
  module Doctor
    # Display logic for diagnostic reports
    class Formatter
      include Output::Formatting

      attr_reader :output, :printer
      private :output, :printer

      SYMBOLS = { ok: "\u2713", warning: '!', error: "\u2717", info: "\u00b7", muted: "\u00b7" }.freeze
      STYLES  = { ok: :success, warning: :warning, error: :failure, info: :muted, muted: :muted }.freeze

      SECTION_LABELS = {
        configuration: 'Configuration',
        tools: 'Tools',
        opportunities: 'Opportunities',
        environment: 'Environment'
      }.freeze

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
        output.newline
        Doctor::Report::SECTIONS.each do |section|
          findings = report.section(section)
          print_section(section, findings) if findings.any?
        end
        print_summary(report)
      end

      private

      def print_section(section, findings)
        printer.puts(:bold, SECTION_LABELS.fetch(section, section.to_s.capitalize))
        findings.each { |finding| print_finding(finding) }
        output.newline
      end

      def print_finding(finding)
        status = finding.status
        message = finding.message
        detail = finding.detail

        symbol = SYMBOLS.fetch(status, ' ')
        style = STYLES.fetch(status, :default)

        printer.print(style, "  #{symbol} ")
        printer.puts(:default, message)
        printer.puts(:muted, "    #{detail}") if detail
      end

      def print_summary(report)
        if report.ok?
          printer.puts(:success, 'No issues found')
        else
          printer.puts(:failure, pluralize(report.errors.size, 'issue found', 'issues found'))
        end
        output.newline
      end
    end
  end
end

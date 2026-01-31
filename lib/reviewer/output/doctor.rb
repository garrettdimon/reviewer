# frozen_string_literal: true

module Reviewer
  class Output
    # Output methods for the `rvw doctor` diagnostic report
    module Doctor
      # Status symbols for each finding type
      SYMBOLS = { ok: "\u2713", warning: '!', error: "\u2717", info: "\u00b7", muted: "\u00b7" }.freeze
      # Output style names mapped from finding statuses
      STYLES  = { ok: :success, warning: :warning, error: :failure, info: :muted, muted: :muted }.freeze

      # Human-readable labels for report sections
      SECTION_LABELS = {
        configuration: 'Configuration',
        tools: 'Tools',
        opportunities: 'Opportunities',
        environment: 'Environment'
      }.freeze

      # Renders a full diagnostic report
      # @param report [Reviewer::Doctor::Report] the report to display
      def doctor_report(report)
        newline
        Reviewer::Doctor::Report::SECTIONS.each do |section|
          findings = report.section(section)
          doctor_section(section, findings) if findings.any?
        end
        doctor_summary(report)
      end

      private

      def doctor_section(section, findings)
        printer.puts(:bold, SECTION_LABELS.fetch(section, section.to_s.capitalize))
        findings.each { |finding| doctor_finding(finding) }
        newline
      end

      def doctor_finding(finding)
        symbol = SYMBOLS.fetch(finding.status, ' ')
        style = STYLES.fetch(finding.status, :default)

        printer.print(style, "  #{symbol} ")
        printer.puts(:default, finding.message)
        printer.puts(:muted, "    #{finding.detail}") if finding.detail
      end

      def doctor_summary(report)
        if report.ok?
          printer.puts(:success, 'No issues found')
        else
          count = report.errors.size
          label = count == 1 ? '1 issue found' : "#{count} issues found"
          printer.puts(:failure, label)
        end
        newline
      end
    end
  end
end

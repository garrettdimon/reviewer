# frozen_string_literal: true

module Reviewer
  module Doctor
    # Reports the status of each configured tool
    class ToolInventory
      attr_reader :report

      # @param report [Doctor::Report] the report to add findings to
      def initialize(report)
        @report = report
      end

      # Reports enabled/disabled status and available commands for each configured tool
      def check
        return unless Reviewer.configuration.file.exist?

        Reviewer.tools.all.each do |tool|
          disabled = tool.disabled?

          report.add(:tools,
                     status: disabled ? :muted : :ok,
                     message: "#{tool.name}: #{disabled ? 'disabled' : 'enabled'}",
                     detail: command_summary(tool))
        end
      end

      private

      def command_summary(tool)
        available = %i[review format install prepare].select { |c| tool.command?(c) }
        "Commands: #{available.join(', ')}"
      end
    end
  end
end

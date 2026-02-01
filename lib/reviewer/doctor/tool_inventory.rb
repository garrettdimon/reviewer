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

      # Reports batch/skip status and available commands for each configured tool
      def check
        return unless Reviewer.configuration.file.exist?

        Reviewer.tools.all.each do |tool|
          skipped = tool.skip_in_batch?

          report.add(:tools,
                     status: skipped ? :muted : :ok,
                     message: "#{tool.name}: #{skipped ? 'skip in batch' : 'runs in batch'}",
                     detail: command_summary(tool))
        end
      end

      private

      def command_summary(tool)
        available = %i[review format install prepare].select { |cmd| tool.command?(cmd) }
        "Commands: #{available.join(', ')}"
      end
    end
  end
end

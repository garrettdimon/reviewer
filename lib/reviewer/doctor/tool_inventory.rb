# frozen_string_literal: true

module Reviewer
  module Doctor
    # Reports the status of each configured tool
    class ToolInventory
      attr_reader :report

      # Creates a tool inventory check that reports batch/skip status for each tool
      # @param report [Doctor::Report] the report to add findings to
      # @param configuration [Configuration] the configuration to check
      # @param tools [Tools] the tools collection to report on
      #
      # @return [ToolInventory]
      def initialize(report, configuration: Reviewer.configuration, tools: Reviewer.tools)
        @report = report
        @configuration = configuration
        @tools = tools
      end

      # Reports batch/skip status and available commands for each configured tool
      def check
        return unless @configuration.file.exist?

        @tools.all.each do |tool|
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

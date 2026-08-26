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
      def initialize(report, configuration:, tools:)
        @report = report
        @configuration = configuration
        @tools = tools
      end

      # Reports batch/skip status and available commands for each configured tool
      def check
        return unless @configuration.file.exist?

        @tools.all.each do |tool|
          report.add_configured_tool(
            key: tool.key,
            name: tool.name,
            skip_in_batch: tool.skip_in_batch?,
            commands: configured_commands(tool),
            files: configured_files(tool),
            source: { path: configuration_path, location: tool.key.to_s }
          )
        end
      end

      private

      def configured_commands(tool)
        tool.commands.slice(:review, :format, :prepare, :install)
      end

      def configured_files(tool)
        tool.settings.config.fetch(:files, {}).slice(
          :review, :format, :pattern, :flag, :separator, :map_to_tests
        ).compact
      end

      def configuration_path
        path = Pathname(@configuration.file)
        return path.to_s unless path.absolute?

        relative = path.relative_path_from(Pathname.pwd)
        relative.to_s.start_with?('../') ? path.to_s : relative.to_s
      end
    end
  end
end

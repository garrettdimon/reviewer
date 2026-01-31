# frozen_string_literal: true

module Reviewer
  module Doctor
    # Suggests improvements based on current configuration and project state
    class OpportunityCheck
      attr_reader :report, :project_dir

      # @param report [Doctor::Report] the report to add findings to
      # @param project_dir [Pathname] the project root for tool detection
      def initialize(report, project_dir)
        @report = report
        @project_dir = project_dir
      end

      # Checks for unconfigured tools, missing file targeting, and missing format commands
      def check
        return unless Reviewer.configuration.file.exist?

        check_unconfigured_tools
        check_missing_files_config
        check_missing_format_command
      end

      private

      def check_unconfigured_tools
        detected = Setup::Detector.new(project_dir).detect
        configured_keys = Reviewer.tools.all.map(&:key)

        detected.each do |result|
          next if configured_keys.include?(result.key)

          report.add(:opportunities, status: :info,
                                     message: "#{result.name} detected but not configured",
                                     detail: result.reasons.join(', '))
        end
      end

      def check_missing_files_config
        Reviewer.tools.all.each do |tool|
          next if tool.disabled?
          next if tool.supports_files?

          report.add(:opportunities, status: :info,
                                     message: "#{tool.name} has no file targeting configured",
                                     detail: 'Add a `files` section to enable staged/modified file scoping')
        end
      end

      def check_missing_format_command
        Reviewer.tools.all.each do |tool|
          next if tool.disabled?
          next if tool.formattable?

          report.add(:opportunities, status: :info,
                                     message: "#{tool.name} has no format command",
                                     detail: 'Add a `format` command to enable `fmt` support')
        end
      end
    end
  end
end

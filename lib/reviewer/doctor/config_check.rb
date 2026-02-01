# frozen_string_literal: true

module Reviewer
  module Doctor
    # Validates the configuration file by delegating to Loader
    class ConfigCheck
      attr_reader :report

      # @param report [Doctor::Report] the report to add findings to
      def initialize(report)
        @report = report
      end

      # Checks for .reviewer.yml existence and validity
      def check
        config_file = Reviewer.configuration.file

        unless config_file.exist?
          report.add(:configuration, status: :error,
                                     message: 'No .reviewer.yml found', detail: 'Run `rvw init` to generate one')
          return
        end

        report.add(:configuration, status: :ok, message: '.reviewer.yml found')
        validate_via_loader
      end

      private

      # Exercises the full Loader pipeline (parse + validate) to surface config errors
      def validate_via_loader
        Loader.configuration
        report.add(:configuration, status: :ok, message: 'Configuration is valid')
      rescue Loader::InvalidConfigurationError => e
        report.add(:configuration, status: :error, message: 'YAML syntax error', detail: e.message)
      rescue Loader::MissingReviewCommandError => e
        report.add(:configuration, status: :error, message: 'Missing review command', detail: e.message)
      end
    end
  end
end

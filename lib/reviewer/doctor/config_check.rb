# frozen_string_literal: true

module Reviewer
  module Doctor
    # Validates the configuration file by delegating to Configuration::Loader
    class ConfigCheck
      attr_reader :report

      # Creates a config check that validates the .reviewer.yml file
      # @param report [Doctor::Report] the report to add findings to
      # @param configuration [Configuration] the configuration to validate
      #
      # @return [ConfigCheck]
      def initialize(report, configuration:)
        @report = report
        @configuration = configuration
      end

      # Checks for .reviewer.yml existence and validity
      def check
        config_file = @configuration.file
        report.set_configuration(path: configuration_path(config_file), state: :missing)

        return :missing unless config_file.exist?

        validate_via_loader(config_file)
      end

      private

      # Exercises the full Configuration::Loader pipeline (parse + validate) to surface config errors
      def validate_via_loader(config_file)
        Configuration::Loader.configuration(file: @configuration.file)
        report.set_configuration(path: configuration_path(config_file), state: :valid)
        :valid
      rescue Configuration::Loader::InvalidConfigurationError => e
        invalid_configuration('Invalid configuration', e.message, config_file)
      rescue Configuration::Loader::MissingReviewCommandError => e
        invalid_configuration('Missing review command', e.message, config_file)
      end

      def invalid_configuration(message, detail, config_file)
        report.add(:configuration, status: :error, message: message, detail: detail)
        report.set_configuration(path: configuration_path(config_file), state: :invalid)
        :invalid
      end

      def configuration_path(config_file)
        path = Pathname(config_file)
        return path.to_s unless path.absolute?

        relative = path.relative_path_from(Pathname.pwd)
        relative.to_s.start_with?('../') ? path.to_s : relative.to_s
      end
    end
  end
end

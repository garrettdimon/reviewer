# frozen_string_literal: true

require_relative 'setup/catalog'
require_relative 'setup/detector'
require_relative 'setup/formatter'
require_relative 'setup/gemfile_lock'
require_relative 'setup/generator'

module Reviewer
  # Handles first-run setup: detecting tools and generating .reviewer.yml
  module Setup
    # URL to the configuration documentation for setup output messages
    CONFIG_URL = 'https://github.com/garrettdimon/reviewer#configuration'

    # Runs the full setup flow: detect tools, generate config, display results
    # @param project_dir [Pathname, String] the project root to scan (defaults to pwd)
    # @param output [Output] the console output handler
    #
    # @return [void]
    def self.run(project_dir: Pathname.pwd, output: Reviewer.output)
      config_file = Reviewer.configuration.file
      formatter = Formatter.new(output)

      if config_file.exist?
        formatter.setup_already_exists(config_file)
        return
      end

      results = Detector.new(project_dir).detect

      if results.empty?
        formatter.setup_no_tools_detected
        return
      end

      yaml = Generator.new(results.map(&:key), project_dir: project_dir).generate
      config_file.write(yaml)
      formatter.setup_success(results)
    end
  end
end

# frozen_string_literal: true

module Reviewer
  module Doctor
    # Detects conflicts between configured tool names, tags, and reserved keywords
    class KeywordCheck
      attr_reader :report

      RESERVED = Arguments::Keywords::RESERVED

      # Creates a keyword check that scans for keyword conflicts in configuration
      # @param report [Doctor::Report] the report to add findings to
      # @param configuration [Configuration] the configuration to check
      # @param tools [Tools] the tools collection to analyze
      #
      # @return [KeywordCheck]
      def initialize(report, configuration:, tools:)
        @report = report
        @configuration = configuration
        @tools = tools
      end

      # Checks for keyword conflicts between tool names, tags, and reserved keywords
      def check
        return unless @configuration.file.exist?

        check_tool_names_vs_reserved
        check_tags_vs_reserved
        check_tool_names_vs_tags
      rescue Configuration::Loader::MissingConfigurationError
        # Tools may reference a stale config path — nothing to check
      end

      private

      def all_tools = @all_tools ||= @tools.all

      def tool_names = all_tools.map { |tool| tool.key.to_s }

      def all_tags = all_tools.flat_map(&:tags).uniq

      # Names of tools that use a given tag
      def tools_with_tag(tag)
        all_tools.select { |tool| tool.tags.include?(tag) }.map(&:name)
      end

      # Tags that belong to tools OTHER than the named tool
      def tags_from_other_tools(tool_name)
        all_tools.reject { |tool| tool.key.to_s == tool_name }.flat_map(&:tags).uniq
      end

      def check_tool_names_vs_reserved
        (tool_names & RESERVED).each do |name|
          report.add(:configuration,
                     status: :warning,
                     message: "Tool name '#{name}' shadows reserved keyword '#{name}'",
                     detail: "Reserved keywords (#{RESERVED.join(', ')}) trigger special behavior. " \
                             'Rename this tool to avoid unexpected results.')
        end
      end

      def check_tags_vs_reserved
        (all_tags & RESERVED).each do |tag|
          report.add(:configuration,
                     status: :warning,
                     message: "Tag '#{tag}' shadows reserved keyword '#{tag}' (used by #{tools_with_tag(tag).join(', ')})",
                     detail: "Reserved keywords (#{RESERVED.join(', ')}) trigger special behavior. " \
                             'Rename this tag or use -t to pass tags explicitly.')
        end
      end

      def check_tool_names_vs_tags
        tool_names.each do |name|
          next unless tags_from_other_tools(name).include?(name)

          report.add(:configuration,
                     status: :warning,
                     message: "Tool name '#{name}' is also a tag on: #{tools_with_tag(name).join(', ')}",
                     detail: "'rvw #{name}' will run both the '#{name}' tool and tagged tools. " \
                             'Use -t to target tags explicitly if this is unintended.')
        end
      end
    end
  end
end

# frozen_string_literal: true

module Reviewer
  # Provides convenient access to subsets of configured tools
  class Tools
    attr_reader :tools, :arguments

    def initialize(tools: self.class.configured, arguments: Reviewer.arguments)
      @tools = tools
      @arguments = arguments
    end

    def all
      tools
    end

    def enabled
      @enabled ||= all.reject { |tool_name, settings| settings[:disabled] }
    end

    def disabled
      @disabled ||= all.keep_if { |tool_name, settings| settings[:disabled] }
    end

    def current
      enabled.keep_if do |tool_name, settings|
        settings.fetch(:tags).intersection(tags).any? || tool_names.include?(tool_name)
      end
    end

    def self.configured
      Loader.new(Reviewer.configuration.file).configuration
    end

    private

    def tags
      arguments.tags.to_a
    end

    def tool_names
      arguments.keywords.for_tool_names.to_a
    end

  end
end

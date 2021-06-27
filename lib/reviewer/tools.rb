# frozen_string_literal: true

module Reviewer
  # Provides convenient access to subsets of configured tools
  class Tools
    attr_reader :tools_hash, :tools, :arguments

    def initialize(tools_hash: self.class.configured, arguments: Reviewer.arguments)
      @tools_hash = tools_hash
      @arguments = arguments
    end

    def all
      tools_hash.keys.map { |tool_name| Tool.new(tool_name) }
    end

    def enabled
      @enabled ||= all.keep_if(&:enabled?)
    end

    def disabled
      @disabled ||= all.keep_if(&:disabled?)
    end

    def current
      if tag_arguments.any? || tool_name_arguments.any?
        enabled.keep_if { |tool| tagged?(tool) || named?(tool) }
      else
        enabled
      end
    end

    def self.configured
      Loader.new(Reviewer.configuration.file).configuration
    end

    private

    def tag_arguments
      arguments.tags.to_a
    end

    def tool_name_arguments
      arguments.tool_names.to_a
    end

    def tagged?(tool)
      tag_arguments.intersection(tool.tags).any?
    end

    def named?(tool)
      tool_name_arguments.include?(tool.key.to_s)
    end
  end
end

# frozen_string_literal: true

module Reviewer
  # Provides convenient access to subsets of configured tools
  class Tools
    attr_reader :configured, :tags, :tool_names

    def initialize(tags: nil, tool_names: nil)
      @configured = Reviewer.configuration.tools
      @tags       = Array(tags)       || Reviewer.arguments.tags.to_a
      @tool_names = Array(tool_names) || Reviewer.arguments.tool_names.to_a
    end

    def all
      configured.keys.map { |tool_name| Tool.new(tool_name) }
    end
    alias to_a all

    def to_h
      configured
    end

    def enabled
      @enabled ||= all.keep_if(&:enabled?)
    end

    def disabled
      @disabled ||= all.keep_if(&:disabled?)
    end

    def current
      if tags.any? || tool_names.any?
        all.keep_if { |tool| tagged?(tool) || named?(tool) }
      else
        enabled
      end
    end

    private

    def tagged?(tool)
      tool.enabled? && tags.intersection(tool.tags).any?
    end

    def named?(tool)
      tool_names.map(&:to_s).include?(tool.key.to_s)
    end
  end
end

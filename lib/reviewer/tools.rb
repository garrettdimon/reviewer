# frozen_string_literal: true

module Reviewer
  # Provides convenient access to subsets of configured tools
  class Tools
    attr_reader :configured, :tags, :tool_names

    def initialize(tags: nil, tool_names: nil)
      @configured = Reviewer.configuration.tools
      @tags       = Array(tags || Reviewer.arguments.tags)
      @tool_names = Array(tool_names || Reviewer.arguments.tool_names)
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

    def specified
      all.keep_if { |tool| named?(tool) }
    end

    def tagged
      enabled.keep_if { |tool| tagged?(tool) }
    end

    def current
      subset? ? (specified + tagged).uniq : enabled
    end

    private

    def subset?
      tool_names.any? || tags.any?
    end

    def tagged?(tool)
      tool.enabled? && tags.intersection(tool.tags).any?
    end

    def named?(tool)
      tool_names.map(&:to_s).include?(tool.key.to_s)
    end
  end
end

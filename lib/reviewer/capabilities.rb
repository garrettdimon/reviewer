# frozen_string_literal: true

require 'json'

module Reviewer
  # Provides machine-readable output describing available tools and usage patterns.
  # Designed for AI agents and automation tools to discover and use Reviewer correctly.
  #
  # @example
  #   puts Reviewer::Capabilities.new.to_json
  class Capabilities
    attr_reader :tools

    # Creates a capabilities report for machine-readable tool discovery
    # @param tools [Tools] the tools collection to report on
    #
    # @return [Capabilities]
    def initialize(tools:)
      @tools = tools
    end

    # Descriptions for the reserved keywords. The keys are derived from
    # Arguments::Keywords::RESERVED rather than restated, so a keyword can never
    # exist in one place and be invisible in the other -- agents are told to use
    # only names this payload lists.
    KEYWORD_DESCRIPTIONS = {
      'staged' => 'Files staged for commit',
      'unstaged' => 'Files with unstaged changes',
      'modified' => 'All changed files',
      'untracked' => 'New files not yet tracked',
      'failed' => 'Tools that failed in the previous run'
    }.freeze

    KEYWORDS = Arguments::Keywords::RESERVED.to_h do |keyword|
      [keyword.to_sym, KEYWORD_DESCRIPTIONS.fetch(keyword, keyword)]
    end.freeze

    SCENARIOS = {
      before_commit: 'rvw staged',
      during_development: 'rvw modified',
      full_review: 'rvw'
    }.freeze

    # Convert capabilities to a hash representation
    #
    # @return [Hash] structured capabilities data
    def to_h
      {
        version: VERSION,
        tools: tools_data,
        tags: tag_list,
        keywords: KEYWORDS,
        scenarios: SCENARIOS
      }
    end

    # Every tag any configured tool carries, including tools excluded from the
    # batch -- `-t <tag>` can select them, so a caller reading this payload needs
    # to see them.
    #
    # @return [Array<String>] sorted unique tags
    def tag_list = tools.all.flat_map(&:tags).uniq.sort

    # Convert capabilities to formatted JSON string
    #
    # @return [String] JSON representation of capabilities
    def to_json(*_args)
      JSON.pretty_generate(to_h)
    end

    private

    # Build tool data from configured tools
    #
    # @return [Array<Hash>] array of tool capability hashes
    def tools_data
      tools.all.map { |tool| tool_data(tool) }
    end

    # Build capability data for a single tool
    #
    # @param tool [Tool] the tool to extract data from
    # @return [Hash] tool capability hash
    def tool_data(tool)
      {
        key: tool.key.to_s,
        name: tool.name,
        description: tool.description,
        tags: tool.tags,
        skip_in_batch: tool.skip_in_batch?,
        commands: {
          review: tool.reviewable?,
          format: tool.formattable?
        }
      }
    end
  end
end

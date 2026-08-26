# frozen_string_literal: true

require 'test_helper'
require 'json'
require 'yaml'

class DocumentationTest < Minitest::Test
  AGENT_GUIDE = 'AGENTS.md'
  DOCUMENTATION_PAGES = %w[
    docs/README.md
    docs/getting-started.md
    docs/usage.md
    docs/configuration.md
    docs/recipes.md
    docs/CONTRIBUTING.md
  ].freeze
  MAINTAINED_MARKDOWN = ['README.md', *DOCUMENTATION_PAGES].freeze
  PUBLIC_LINK_SOURCES = [
    *MAINTAINED_MARKDOWN,
    '.reviewer.example.yml',
    'reviewer.gemspec',
    'lib/reviewer/setup.rb'
  ].freeze
  CANONICAL_REPOSITORY_URL = %r{
    (?<url>
      https://github\.com/garrettdimon/reviewer/blob/main/
      (?<path>[A-Za-z0-9_./-]+)
      (?:\#(?<anchor>[A-Za-z0-9_-]+))?
    )
  }x

  def test_maintained_documentation_pages_exist
    missing_pages = DOCUMENTATION_PAGES.reject { |page| File.file?(page) }

    assert_empty missing_pages, "Missing documentation pages: #{missing_pages.join(', ')}"
  end

  def test_agent_guide_delegates_to_contributor_guide
    assert File.file?(AGENT_GUIDE), "Missing #{AGENT_GUIDE}"
    assert_includes markdown_targets(File.read(AGENT_GUIDE)), 'docs/CONTRIBUTING.md'
    assert_relative_links_resolve(AGENT_GUIDE)
  end

  def test_documentation_navigation_is_relative_and_resolves
    index_targets = markdown_targets(File.read('docs/README.md'))
    expected_index_targets = DOCUMENTATION_PAGES.drop(1).map { |page| File.basename(page) }
    assert_empty expected_index_targets - index_targets

    DOCUMENTATION_PAGES.drop(1).each do |page|
      assert_includes markdown_targets(File.read(page)), 'README.md', "#{page} must link to the documentation index"
    end

    MAINTAINED_MARKDOWN.each { |page| assert_relative_links_resolve(page) }
  end

  def test_readme_keeps_one_configuration_compatibility_heading
    readme = File.read('README.md')
    section = readme[/^## Configuration\n(?<body>.*?)(?=^## |\z)/m, :body]

    assert_equal 1, readme.scan(/^## Configuration$/).size
    assert_includes markdown_targets(section), 'docs/configuration.md'
  end

  def test_getting_started_structures_setup_around_doctor
    markdown = File.read('docs/getting-started.md')
    commands = fenced_blocks(markdown, 'console').flat_map(&:lines).map(&:strip)
    reports = fenced_blocks(markdown, 'json').map { |block| JSON.parse(block) }

    assert_operator commands.count('rvw doctor'), :>=, 2
    report = reports.find { |value| value['schema_version'] == 1 }
    refute_nil report, 'Getting started must include a valid Doctor JSON report'
    assert_kind_of Array, report['configured_tools']
    assert_kind_of Array, report['discoveries']
  end

  def test_canonical_repository_urls_resolve_to_tracked_markdown
    canonical_repository_urls.each do |url, path, anchor|
      assert_includes `git ls-files -- #{path}`.lines.map(&:chomp), path, "#{url} must target a tracked file"
      assert File.file?(path), "#{url} must target a file"
      assert_includes markdown_anchors(path), anchor, "#{url} must target an existing anchor" if anchor
    end
  end

  def test_public_documentation_and_runtime_sources_do_not_target_the_wiki
    wiki_sources = PUBLIC_LINK_SOURCES.select do |source|
      File.read(source).include?('github.com/garrettdimon/reviewer/wiki')
    end

    assert_empty wiki_sources, "Wiki links remain in: #{wiki_sources.join(', ')}"
  end

  def test_example_configuration_contains_only_supported_keys
    tool = YAML.safe_load_file('.reviewer.example.yml').fetch('tool-name-key')

    supported_keys = [
      [tool, %w[skip_in_batch name description tags links commands files env flags summary]],
      [tool.fetch('links'), %w[home install ignore_syntax disable_syntax]],
      [tool.fetch('commands'), %w[install prepare review format max_exit_status]],
      [tool.fetch('files'), %w[review format flag separator pattern map_to_tests]],
      [tool.fetch('summary', {}), %w[pattern label]]
    ]

    supported_keys.each { |configuration, supported| assert_equal supported.sort, configuration.keys.sort }
  end

  def test_gem_metadata_uses_repository_documentation_without_a_wiki
    metadata = Gem::Specification.load('reviewer.gemspec').metadata

    assert_equal 'https://github.com/garrettdimon/reviewer/blob/main/docs/README.md', metadata['documentation_uri']
    refute metadata.key?('wiki_uri')
    assert_equal 'https://github.com/garrettdimon/reviewer', metadata['homepage_uri']
    assert_equal 'https://github.com/garrettdimon/reviewer/issues', metadata['bug_tracker_uri']
    assert_equal 'https://github.com/garrettdimon/reviewer/CHANGELOG.md', metadata['changelog_uri']
    assert_equal 'https://github.com/garrettdimon/reviewer', metadata['source_code_uri']
  end

  private

  def markdown_targets(markdown)
    markdown.to_s.scan(/(?<!!)\[[^\]]+\]\(([^)]+)\)/).flatten
  end

  def fenced_blocks(markdown, language)
    markdown.scan(/^```#{Regexp.escape(language)}\n(.*?)^```$/m).flatten
  end

  def assert_relative_links_resolve(source)
    markdown_targets(File.read(source)).each do |target|
      next if target.match?(%r{\A(?:[a-z]+:)?//}i)

      path, anchor = target.split('#', 2)
      destination = path.empty? ? source : File.expand_path(path, File.dirname(source))
      assert File.file?(destination), "#{source} links to missing #{target}"
      assert_includes markdown_anchors(destination), anchor, "#{source} links to missing #{target}" if anchor
    end
  end

  def markdown_anchors(path)
    File.readlines(path).filter_map do |line|
      heading = line[/^#+\s+(.+)$/, 1]
      heading.downcase.gsub(/[^a-z0-9 _-]/, '').tr(' ', '-') if heading
    end
  end

  def canonical_repository_urls
    PUBLIC_LINK_SOURCES.flat_map do |source|
      File.read(source).scan(CANONICAL_REPOSITORY_URL)
    end
  end
end

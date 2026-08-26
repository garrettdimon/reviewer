# frozen_string_literal: true

require 'test_helper'
require 'yaml'

module Reviewer
  module Setup
    class ToolBlockTest < Minitest::Test
      def test_renders_name_description_and_tags
        block = tool_block(:rubocop)
        output = block.to_s

        assert_includes output, 'rubocop:'
        assert_includes output, '  name: RuboCop'
        assert_includes output, '  tags: [ruby, syntax]'
      end

      def test_renders_description_as_comment
        block = tool_block(:rubocop)
        output = block.to_s

        assert output.start_with?('# Review Ruby syntax and formatting for consistency')
      end

      def test_renders_commands
        block = tool_block(:rubocop)
        output = block.to_s

        assert_includes output, '  commands:'
        assert_includes output, '    review:'
        assert_includes output, '    format:'
      end

      def test_renders_tool_without_files_section
        block = tool_block(:flog)
        output = block.to_s

        refute_includes output, '  files:'
      end

      def test_renders_files_section_with_targeting
        block = tool_block(:rubocop)
        output = block.to_s

        assert_includes output, '  files:'
        assert_includes output, "    flag: ''"
        assert_includes output, "    separator: ' '"
        assert_includes output, '    pattern: '
      end

      def test_renders_file_scoped_review_command
        block = tool_block(:tests)
        output = block.to_s

        assert_includes output, '  files:'
        assert_includes output, '    review: bundle exec ruby -Itest'
      end

      def test_renders_map_to_tests
        block = tool_block(:tests)
        output = block.to_s

        assert_includes output, '    map_to_tests: minitest'
      end

      def test_preserves_top_level_commands
        definition = {
          name: 'JavaScript tool',
          description: 'Checks JavaScript',
          commands: {
            review: 'npx example check',
            format: 'npx example check --fix'
          }
        }

        output = ToolBlock.new(:javascript, definition).to_s
        commands = YAML.safe_load(output).fetch('javascript').fetch('commands')

        assert_equal definition[:commands].transform_keys(&:to_s), commands
      end

      def test_preserves_file_scoped_commands
        definition = {
          name: 'JavaScript tool',
          description: 'Checks JavaScript',
          commands: { review: 'npx example check' },
          files: {
            review: 'npx example check-file',
            format: 'npx example check-file --fix'
          }
        }

        output = ToolBlock.new(:javascript, definition).to_s
        files = YAML.safe_load(output).fetch('javascript').fetch('files')

        assert_equal definition[:files].transform_keys(&:to_s), files
      end

      def test_does_not_alter_non_npx_commands
        block = tool_block(:rubocop)
        output = block.to_s

        assert_includes output, 'bundle exec rubocop'
      end

      def test_quotes_values_with_special_characters
        definition = {
          name: 'Test Tool',
          description: 'A tool: with special #chars',
          commands: { review: 'run --flag' }
        }
        block = ToolBlock.new(:test_tool, definition)
        output = block.to_s

        assert_includes output, "'A tool: with special #chars'"
      end

      def test_does_not_quote_simple_values
        definition = {
          name: 'Simple',
          description: 'No special chars here',
          commands: { review: 'bundle exec test' }
        }
        block = ToolBlock.new(:simple, definition)
        output = block.to_s

        assert_includes output, '  name: Simple'
        assert_includes output, '  description: No special chars here'
      end

      def test_quotes_yaml_bare_words
        definition = {
          name: 'true',
          description: 'A test tool',
          commands: { review: 'run' }
        }
        block = ToolBlock.new(:bare, definition)
        output = block.to_s

        assert_includes output, "  name: 'true'"
      end

      def test_quotes_empty_strings
        definition = {
          name: 'Tool',
          description: 'Desc',
          commands: { review: 'run' },
          files: { flag: '', separator: ' ', pattern: '*.rb' }
        }
        block = ToolBlock.new(:tool, definition)
        output = block.to_s

        assert_includes output, "    flag: ''"
      end

      def test_output_ends_with_trailing_newline
        block = tool_block(:flog)
        output = block.to_s

        assert output.end_with?("\n"), 'Expected trailing newline for YAML block separation'
      end

      def test_renders_commands_in_order
        block = tool_block(:bundle_audit)
        output = block.to_s
        lines = output.lines.map(&:strip)

        install_idx = lines.index { |l| l.start_with?('install:') }
        prepare_idx = lines.index { |l| l.start_with?('prepare:') }
        review_idx = lines.index { |l| l.start_with?('review:') }

        assert install_idx < prepare_idx, 'install should come before prepare'
        assert prepare_idx < review_idx, 'prepare should come before review'
      end

      private

      def tool_block(key)
        ToolBlock.new(key, Catalog.config_for(key))
      end
    end
  end
end

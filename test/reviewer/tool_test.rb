# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class ToolTest < MiniTest::Test
    def setup
      Reviewer.configure do |config|
        config.file = 'test/fixtures/files/test_commands.yml'
      end
      @tool = Tool.new(:enabled_tool)
    end

    def test_installation_command
      cmd = @tool.installation_command
      assert_equal "WITH_SPACES='with spaces'; WORD=second; INTEGER=1; BOOLEAN=true; bundle exec gem install example", cmd
    end

    def test_preparation_command
      cmd = @tool.preparation_command
      assert_equal "WITH_SPACES='with spaces'; WORD=second; INTEGER=1; BOOLEAN=true; bundle exec example update --quiet > /dev/null", cmd
    end

    def test_review_command
      cmd = @tool.review_command
      assert_equal "WITH_SPACES='with spaces'; WORD=second; INTEGER=1; BOOLEAN=true; bundle exec example review --third 'third flag' --fourth 'fourth flag' --quiet > /dev/null", cmd
    end

    def test_format_command
      cmd = @tool.format_command
      assert_equal "WITH_SPACES='with spaces'; WORD=second; INTEGER=1; BOOLEAN=true; bundle exec example format", cmd
    end
  end
end

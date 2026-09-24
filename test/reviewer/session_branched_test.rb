# frozen_string_literal: true

require 'test_helper'

module Reviewer
  # How a session reports `branched` requests it can't honor
  class SessionBranchedTest < Minitest::Test
    def test_branched_without_a_base_is_a_usage_error
      in_repository_without_origin_head do
        session = build_session(arguments: Arguments.new(%w[branched]))
        output, = capture_subprocess_io { assert_equal Session::USAGE_ERROR, session.review }

        assert_match(%r{origin/HEAD isn't set}, output)
        assert_match(/git remote set-head origin --auto/, output)
      end
    end

    def test_branched_without_a_base_reports_json
      in_repository_without_origin_head do
        session = build_session(arguments: Arguments.new(%w[branched --json]))
        output, = capture_subprocess_io { assert_equal Session::USAGE_ERROR, session.review }
        payload = JSON.parse(output)

        assert_equal 'error', payload['state']
        assert_equal 'missing_base', payload.dig('error', 'code')
      end
    end

    def test_branched_outside_a_repository_reports_gits_error_instead_of_a_fix
      with_swapped_config(Reviewer.configuration.file.expand_path) do
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            session = build_session(arguments: Arguments.new(%w[branched]))
            output, = capture_subprocess_io { assert_equal Session::USAGE_ERROR, session.review }

            assert_match(/not a git repository/, output)
            refute_match(/set-head/, output)
          end
        end
      end
    end

    def test_branched_with_a_branch_name_hints_that_it_takes_none
      tools_collection = Tools.new(config_file: Reviewer.configuration.file)
      session = build_session(arguments: Arguments.new(%w[branched main]), tools: tools_collection)
      output, = capture_subprocess_io { assert_equal Session::USAGE_ERROR, session.review }

      assert_match(/Unrecognized: main/, output)
      assert_match(%r{'branched' always compares against origin/HEAD and doesn't take a branch name}, output)
    end

    def test_branched_with_a_branch_name_includes_the_hint_in_json
      session = build_session(arguments: Arguments.new(%w[branched main --json]))
      output, = capture_subprocess_io { assert_equal Session::USAGE_ERROR, session.review }
      error = JSON.parse(output).fetch('error')

      assert_equal 'unrecognized_selector', error['code']
      assert_match(/doesn't take a branch name/, error['hint'])
    end

    private

    def build_session(arguments:, tools: nil)
      context = Context.new(arguments: arguments, output: Output.new, history: Reviewer.history)
      Session.new(context: context, tools: tools || Reviewer.tools)
    end

    # The fixture config path is relative, so it's made absolute before leaving the project root
    def in_repository_without_origin_head(&)
      with_swapped_config(Reviewer.configuration.file.expand_path) do
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            system('git', 'init', '--quiet', '-b', 'main', exception: true)
            system('git', 'remote', 'add', 'origin', File.join(dir, 'missing.git'), exception: true)
            yield
          end
        end
      end
    end
  end
end

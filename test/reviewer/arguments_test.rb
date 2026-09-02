# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class ArgumentsTest < Minitest::Test
    def test_has_an_empty_array_of_tags_by_default
      args = %w[]
      arguments = Arguments.new(args)
      assert_equal [], arguments.tags.raw
    end

    def test_parses_individual_tags_from_command_line
      args = %w[-t ruby]
      arguments = Arguments.new(args)
      assert_equal %w[ruby], arguments.tags.raw
    end

    def test_version_flag_sets_version_predicate
      arguments = Arguments.new(%w[-v])
      assert arguments.version?
    end

    def test_help_flag_sets_help_predicate
      arguments = Arguments.new(%w[-h])
      assert arguments.help?
    end

    def test_parses_multiple_tags_from_command_line
      args = %w[-t ruby,css]
      arguments = Arguments.new(args)
      assert_equal %w[ruby css], arguments.tags.raw
    end

    def test_has_an_empty_array_of_files_by_default
      args = %w[]
      arguments = Arguments.new(args)
      assert_equal [], arguments.files.raw
    end

    def test_parses_individual_files_from_command_line
      args = %w[-f ./app/**/*.rb]
      arguments = Arguments.new(args)
      assert_equal ['./app/**/*.rb'], arguments.files.raw
    end

    def test_parses_multiple_files_from_command_line
      args = %w[-f ./app/**/*.rb,./test/**/*.rb]
      arguments = Arguments.new(args)
      assert_equal ['./app/**/*.rb', './test/**/*.rb'], arguments.files.raw
    end

    def test_rejects_a_files_option_without_a_value
      assert Arguments.new(%w[-f]).invalid_files_option?
      assert Arguments.new(%w[--files]).invalid_files_option?
    end

    def test_rejects_an_empty_files_option
      assert Arguments.new(['-f', '']).invalid_files_option?
      assert Arguments.new(['--files=']).invalid_files_option?
      assert Arguments.new(['-f,']).invalid_files_option?
      assert Arguments.new(%w[-jf]).invalid_files_option?
      assert Arguments.new(%w[-jfr]).invalid_files_option?
    end

    def test_rejects_a_whitespace_only_files_option
      assert Arguments.new(['-f', '   ']).invalid_files_option?
      assert Arguments.new(['--files=   ']).invalid_files_option?
      assert Arguments.new(['-f', ' , ']).invalid_files_option?
    end

    def test_rejects_an_empty_files_option_among_repeated_values
      assert Arguments.new(['-f', 'app/a.rb', '-f']).invalid_files_option?
      assert Arguments.new(['-f', '', '-f', 'app/a.rb']).invalid_files_option?
    end

    def test_accepts_every_supported_files_option_form
      arguments = {
        %w[-f app/a.rb] => %w[app/a.rb],
        %w[--files app/a.rb] => %w[app/a.rb],
        %w[-f=app/a.rb] => %w[app/a.rb],
        %w[--files=app/a.rb] => %w[app/a.rb],
        %w[-fapp/a.rb] => %w[app/a.rb],
        %w[-jf app/a.rb] => %w[app/a.rb],
        %w[-jf=app/a.rb] => %w[app/a.rb],
        %w[-f app/a.rb,app/b.rb] => %w[app/a.rb app/b.rb],
        %w[-f app/a.rb -f app/b.rb] => %w[app/a.rb app/b.rb],
        %w[-f -generated.rb] => %w[-generated.rb],
        %w[-f=-generated.rb] => %w[-generated.rb]
      }

      arguments.each do |args, files|
        parsed = Arguments.new(args)

        refute parsed.invalid_files_option?, args.inspect
        assert_equal files, parsed.files.raw, args.inspect
      end
    end

    def test_accepts_compact_file_value_ending_in_f_before_json
      arguments = Arguments.new(%w[-fprofile.pdf --json])

      refute arguments.invalid_files_option?
      assert_equal %w[profile.pdf], arguments.files.raw
      assert arguments.json?
    end

    def test_compact_file_value_does_not_leak_a_format_value
      arguments = Arguments.new(%w[-fmain.tf --format summary])

      assert_equal %w[main.tf], arguments.files.raw
      assert_equal :summary, arguments.format
      assert_empty arguments.keywords.raw
    end

    def test_compact_file_value_does_not_leak_a_tag_value
      arguments = Arguments.new(%w[-fmain.tf --tags ruby])

      assert_equal %w[main.tf], arguments.files.raw
      assert_equal %w[ruby], arguments.tags.raw
      assert_empty arguments.keywords.raw
    end

    def test_rejects_a_files_option_followed_by_another_known_option
      assert Arguments.new(%w[-f --json]).invalid_files_option?
      assert Arguments.new(%w[-f --tags ruby]).invalid_files_option?
      assert Arguments.new(%w[-f -j=true]).invalid_files_option?
      assert Arguments.new(%w[-f --json=true]).invalid_files_option?
    end

    def test_exposes_leftover_arguments_as_keywords
      args = %w[staged -t ruby invalid]
      arguments = Arguments.new(args)
      assert_equal %w[staged invalid], arguments.keywords.raw
    end

    def test_exposes_flagless_arguments_as_keywords
      args = %w[enabled_tool]
      arguments = Arguments.new(args)
      assert_equal args, arguments.keywords.raw
    end

    def test_gracefully_handles_robust_sets_of_arguments
      args = %w[staged --tags ruby,css --files ./app/**/*.rb,./test/**/*.rb]
      arguments = Arguments.new(args)
      assert_equal %w[staged], arguments.keywords.raw
      assert_equal %w[ruby css], arguments.tags.raw
      assert_equal ['./app/**/*.rb', './test/**/*.rb'], arguments.files.raw
    end

    def test_passes_reserved_keywords_to_files
      arguments = Arguments.new(%w[staged])
      assert_includes arguments.files.keywords, 'staged'
    end

    def test_defines_custom_inspect
      args = %w[staged --tags ruby,css --files ./app/**/*.rb,./test/**/*.rb]
      arguments = Arguments.new(args)
      hash = arguments.inspect
      assert hash.key?(:files)
      assert hash.key?(:tags)
      assert hash.key?(:keywords)
    end
  end

  class ArgumentsFlagsTest < Minitest::Test
    def test_raw_is_false_by_default
      refute Arguments.new([]).raw?
    end

    def test_parses_short_raw_flag
      assert Arguments.new(%w[-r]).raw?
    end

    def test_parses_long_raw_flag
      assert Arguments.new(%w[--raw]).raw?
    end

    def test_raw_flag_works_with_other_options
      arguments = Arguments.new(%w[-r -t ruby staged])
      assert arguments.raw?
      assert_equal %w[ruby], arguments.tags.raw
    end

    def test_json_is_false_by_default
      refute Arguments.new([]).json?
    end

    def test_parses_short_json_flag
      assert Arguments.new(%w[-j]).json?
    end

    def test_parses_long_json_flag
      assert Arguments.new(%w[--json]).json?
    end

    def test_json_flag_works_with_other_options
      arguments = Arguments.new(%w[-j -t ruby staged])
      assert arguments.json?
      assert_equal %w[ruby], arguments.tags.raw
    end

    def test_json_flag_survives_a_missing_files_value
      assert Arguments.new(%w[-f --json]).json?
      assert Arguments.new(%w[-f -j]).json?
    end

    def test_json_format_survives_a_missing_files_value
      assert_equal :json, Arguments.new(%w[-f --format json]).format
      assert_equal :json, Arguments.new(%w[-f --format=json]).format
    end

    def test_json_boolean_value_survives_a_missing_files_value
      assert Arguments.new(%w[-f -j=true]).json?
      assert Arguments.new(%w[-f --json=true]).json?
      refute Arguments.new(%w[-f -j=false]).json?
      refute Arguments.new(%w[-f --json=false]).json?
    end

    def test_compact_file_value_is_not_reinterpreted_as_json
      refute Arguments.new(%w[-fproject.rb -f]).json?
    end

    def test_repeated_formats_keep_last_value_precedence
      assert_equal :json, Arguments.new(%w[--format summary --format json]).format
      assert_equal :summary, Arguments.new(%w[--format json --format summary]).format
    end

    def test_option_terminator_keeps_following_output_flags_positional
      refute Arguments.new(%w[-- --json]).json?
      assert_equal :summary, Arguments.new(%w[--format summary -- --format json]).format
    end

    # --format flag tests
    def test_format_defaults_to_streaming
      assert_equal :streaming, Arguments.new([]).format
    end

    def test_parses_format_summary
      assert_equal :summary, Arguments.new(%w[--format summary]).format
    end

    def test_parses_format_json
      assert_equal :json, Arguments.new(%w[--format json]).format
    end

    def test_format_requires_long_flag
      # No short flag for --format; -m is not valid
      assert_raises(Slop::UnknownOption) { Arguments.new(%w[-m summary]) }
    end

    def test_json_flag_sets_format_to_json
      assert_equal :json, Arguments.new(%w[--json]).format
    end

    def test_format_flag_works_with_other_options
      arguments = Arguments.new(%w[--format summary -t ruby staged])
      assert_equal :summary, arguments.format
      assert_equal %w[ruby], arguments.tags.raw
    end

    # streaming? tests
    def test_streaming_true_by_default
      assert Arguments.new([]).streaming?
    end

    def test_streaming_false_for_summary_format
      refute Arguments.new(%w[--format summary]).streaming?
    end

    def test_streaming_false_for_json_format
      refute Arguments.new(%w[--format json]).streaming?
    end

    def test_streaming_false_for_json_flag
      refute Arguments.new(%w[--json]).streaming?
    end

    def test_invalid_format_falls_back_to_streaming
      out, _err = capture_subprocess_io do
        arguments = Arguments.new(%w[--format verbose])
        assert_equal :streaming, arguments.format
      end
      assert_match(/Unknown format 'verbose'/, out)
      assert_match(/Valid formats:/, out)
    end

    def test_valid_formats_not_warned
      out, _err = capture_subprocess_io do
        arguments = Arguments.new(%w[--format summary])
        assert_equal :summary, arguments.format
      end
      refute_match(/Unknown format/, out)
    end

    def test_exposes_capabilities_options
      assert Arguments.new(%w[--capabilities]).capabilities?
      assert Arguments.new(%w[-c]).capabilities?
    end

    def test_does_not_parse_capabilities_after_the_option_terminator
      refute Arguments.new(%w[-- --capabilities]).capabilities?
    end
  end

  class ArgumentsRunnerStrategyTest < Minitest::Test
    def test_returns_passthrough_when_raw
      arguments = Arguments.new(%w[-r])
      assert_equal Runner::Strategies::Passthrough, arguments.runner_strategy(multiple_tools: true)
      assert_equal Runner::Strategies::Passthrough, arguments.runner_strategy(multiple_tools: false)
    end

    def test_returns_captured_for_non_streaming_format
      arguments = Arguments.new(%w[--format summary])
      assert_equal Runner::Strategies::Captured, arguments.runner_strategy(multiple_tools: true)
      assert_equal Runner::Strategies::Captured, arguments.runner_strategy(multiple_tools: false)
    end

    def test_returns_captured_for_streaming_with_multiple_tools
      arguments = Arguments.new([])
      assert_equal Runner::Strategies::Captured, arguments.runner_strategy(multiple_tools: true)
    end

    def test_returns_passthrough_for_streaming_with_single_tool
      arguments = Arguments.new([])
      assert_equal Runner::Strategies::Passthrough, arguments.runner_strategy(multiple_tools: false)
    end
  end
end

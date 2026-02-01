# frozen_string_literal: true

require 'test_helper'

module Reviewer
  module Setup
    class CatalogTest < Minitest::Test
      def test_all_returns_a_frozen_hash
        assert_kind_of Hash, Catalog.all
        assert Catalog.all.frozen?
      end

      def test_every_entry_has_a_review_command
        Catalog.all.each do |key, definition|
          commands = definition[:commands]
          assert commands.key?(:review), "#{key} is missing a :review command"
        end
      end

      def test_every_entry_has_detect_signals
        Catalog.all.each do |key, definition|
          detect = definition[:detect]
          assert_kind_of Hash, detect, "#{key} is missing :detect hash"

          has_signal = detect.key?(:gems) || detect.key?(:files) || detect.key?(:directories)
          assert has_signal, "#{key} has no detection signals (gems, files, or directories)"
        end
      end

      def test_every_entry_has_name_and_description
        Catalog.all.each do |key, definition|
          assert definition.key?(:name), "#{key} is missing :name"
          assert definition.key?(:description), "#{key} is missing :description"
        end
      end

      def test_includes_known_tools
        keys = Catalog.all.keys
        assert_includes keys, :bundle_audit
        assert_includes keys, :rubocop
        assert_includes keys, :reek
        assert_includes keys, :tests
        assert_includes keys, :specs
      end

      def test_config_for_returns_definition_without_detect
        config = Catalog.config_for(:rubocop)
        assert config.key?(:commands)
        refute config.key?(:detect)
      end

      def test_config_for_unknown_key_returns_nil
        assert_nil Catalog.config_for(:nonexistent_tool)
      end

      def test_detect_for_returns_detect_hash
        detect = Catalog.detect_for(:rubocop)
        assert_kind_of Hash, detect
        assert detect.key?(:gems) || detect.key?(:files)
      end

      def test_detect_for_unknown_key_returns_nil
        assert_nil Catalog.detect_for(:nonexistent_tool)
      end

      def test_tests_entry_has_file_scoped_review_command
        config = Catalog.config_for(:tests)
        assert_equal 'bundle exec rake test', config[:commands][:review]
        assert_equal 'bundle exec ruby -Itest', config[:files][:review]
        assert_equal '*_test.rb', config[:files][:pattern]
        assert_equal 'minitest', config[:files][:map_to_tests]
      end
    end
  end
end

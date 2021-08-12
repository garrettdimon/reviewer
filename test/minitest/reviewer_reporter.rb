module Minitest
  # Custom minitest reporter just for Reviewer. Focuses on printing directly actionable guidance.
  # - Colorize the Output
  # - What files had the most errors?
  # - Show the most impacted areas first.
  # - Show lowest-level (most nested code) frist.
  #
  # Pulls from existing reporters:
  #   https://github.com/seattlerb/minitest/blob/master/lib/minitest.rb#L554
  #
  # Lots of insight from:
  #   http://www.monkeyandcrow.com/blog/reading_ruby_minitest_plugin_system/
  #
  # And a good example available at:
  #   https://github.com/adamsanderson/minitest-snail
  #
  # Pulls from minitest-color as well:
  #   https://github.com/teoljungberg/minitest-color/blob/master/lib/minitest/color_plugin.rb
  class ReviewerReporter < Reporter
    require_relative 'reviewer_reporter/output'

    attr_reader :output, :successes, :skips, :failures, :errors, :snails, :heat_map

    Location = Struct.new(:result) do
      # 1. Test Location - Where does the test start?
      # 2. Failure Location - What line actually failed?
      # 3. Exception Location - What is the most critial line in the exception?

      def class_name
        result.class_name
      end

      def file
        reduced_path(location[0])
      end

      def line
        location[1]
      end

      def test_file
        reduced_path(test_location[0])
      end

      def test_line
        test_location[1]
      end

      def to_a
        location
      end

      def to_s
        to_a.join(':')
      end

      private

      def reduced_path(path)
        "/#{path.split("/#{project_directory_name}/").last}"
      end

      def pwd
        Dir.pwd
      end

      def project_directory_name
        pwd.split('/').last
      end

      def location
        if result.error?
          exception_location
        else
          test_location
        end
      end

      def test_location
        result.source_location
      end

      def failure_location
      end

      def exception_location
        failure&.backtrace.first.split(':')
      end

      def failure
        result.failures.select { |f| UnexpectedError === f }.first
      end
    end

    def initialize
      @output = Output.new
      @successes = []
      @skips = []
      @failures = []
      @errors = []
      @snails = []
      @heat_map = {}
    end

    # Starts reporting on the run.
    def start
    end

    # About to start running a test. This allows a reporter to show that it is starting or that we
    # are in the middle of a test run.
    def prerecord(klass, name)
    end

    # Minitest::Result source:
    #   https://github.com/seattlerb/minitest/blob/f4f57afaeb3a11bd0b86ab0757704cb78db96cf4/lib/minitest.rb#L504
    def record(result)
      # result.passed?
      #   did it pass?
      # result.skipped?
      #   was it skipped?
      # result.error?
      #   was there an exception?
      # result.result_code
      #   ., E, F, S
      # result.name -> Test Name
      #   "test_quiet_runner_standard_failure_implementation"
      # result.class_name -> Tested Class
      #   "Reviewer::Runner::Strategies::SilentTest"
      # result.assertions -> Integer of Successful Assertions before Failure
      #   0
      # result.time -> Elapsed Time
      #   8.100015111267567e-05
      # result.failures -> Array of Failure Reasons/Exceptions
      #   [ Minitest::UnexpectedError: Unexpected exception ]
      # result.source_location -> Line & Line Numberk
      #   [ "/Users/garrettdimon/Code/reviewer/test/reviewer/runner/strategies/captured_test.rb", 28 ]

      save_and_file(result)
      update_heat_map(result)

      output.marker(result.result_code)
    end

    # Outputs the summary of the run.
    def report
      output.puts
      output.puts
      output.compact_summary(errors.size, failures.size, skips.size)

      update_coverage_in_heat_map
      show_heat_map

    end

    # Did this run pass?
    def passed?
      errors.empty? && failures.empty?
    end

    private

    def failure?
      ->(result) { result.failures.any? }
    end

    def error?
      ->(result) { result.error? }
    end

    def skipped?
      ->(result) { result.skipped? }
    end

    def save_and_file(result)
      case result
      when error? then @errors
      when skipped? then @skips
      when failure? then @failures
      else @successes
      end << result
    end

    def update_heat_map(result)
      location = Location.new(result)
      # {
      #   '<file_path|class_name>' => {
      #     23 => {
      #       errors: 3,
      #       failures: 2,
      #       skips: 0,
      #       coverage: 0,
      #       slows: 0
      #     },
      #     36 => {
      #       errors: 10,
      #       failures: 2,
      #       skips: 0,
      #       coverage: 0,
      #       slows: 0
      #     }
      #   }
      # }

      if heat_map[location.file].nil?
        @heat_map[location.file] = { location.line => 1 }
      elsif heat_map[location.file][location.line].nil?
        @heat_map[location.file][location.line] = 1
      else
        @heat_map[location.file][location.line] += 1
      end
    end

    def show_heat_map
      heat_map.each_pair do |locations, lines|
        lines.sort_by do |line|
          Integer(line[0]) # Line Number
        end
      end.sort_by do |location|
        location[1].values.sum
      end.reverse.take(10).each do |location, lines|
        # line_numbers_max_length = lines.keys.map { |key| key.to_s.length }.max
        # line_hits_max_length = lines.values.map { |value| value.to_s.length }.max
        # max_length = line_numbers_max_length + COUNT_SEPARATOR.length + line_hits_max_length
        # location_offset = ' ' * location.length
        output.puts
        output.puts location
        lines.each do |line_counts|
          line = line_counts[0].to_s
          hits = line_counts[1]
          errors = 'E' * hits
          output.puts  '  :' + line + ' ' + errors
        end
      end
    end

    def update_coverage_in_heat_map
      # TODO
    end

    def coverage?
      # ENV['COVERAGE'] && coverage/coverage.json exists?
    end
  end
end

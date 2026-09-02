# frozen_string_literal: true

require 'json'

tool = ARGV.shift
File.open(ENV.fetch('INVOCATION_LOG'), 'a') do |log|
  log.puts JSON.generate(tool: tool, argv: ARGV)
end

if ENV['FAILING_TOOL'] == tool
  puts "#{ENV['FAILED_PATH']}:1: failure" if ENV['FAILED_PATH']
  exit 1
end

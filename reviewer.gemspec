# frozen_string_literal: true

require_relative 'lib/reviewer/version'

Gem::Specification.new do |spec|
  spec.name          = 'reviewer'
  spec.version       = Reviewer::VERSION
  spec.authors       = ['Garrett Dimon']
  spec.email         = ['email@garrettdimon.com']

  spec.summary       = 'Frictionless code quality. One command for all your review tools.'
  spec.description   = 'Run tests, linters, security audits, and formatters with a single command. ' \
                       'Reviewer wraps your code quality tools into a consistent interface with ' \
                       'git-aware file targeting, auto-detection, and multiple output formats.'
  spec.homepage      = 'https://github.com/garrettdimon/reviewer'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.2')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['bug_tracker_uri'] = 'https://github.com/garrettdimon/reviewer/issues'
  spec.metadata['changelog_uri'] = 'https://github.com/garrettdimon/reviewer/blob/main/CHANGELOG.md'
  spec.metadata['documentation_uri'] = 'https://github.com/garrettdimon/reviewer/blob/main/docs/README.md'
  spec.metadata['source_code_uri'] = 'https://github.com/garrettdimon/reviewer'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Package only what a consumer needs. An allowlist keeps development files out
  # of the gem by default, so new tooling config cannot leak into a release.
  packaged_root_files = %w[
    README.md CHANGELOG.md LICENSE.txt CODE_OF_CONDUCT.md
    .reviewer.example.yml reviewer.gemspec
  ]
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").select do |f|
      f.start_with?('lib/', 'exe/', 'docs/') || packaged_root_files.include?(f)
    end
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'benchmark', '~> 0.5'
  spec.add_dependency 'pstore', '~> 0.2'
  spec.add_dependency 'rainbow', '~> 3.1'
  spec.add_dependency 'ruby-progressbar', '~> 1.13'
  spec.add_dependency 'slop', '~> 4.10'

  spec.add_development_dependency 'minitest', '~> 5.27'
  spec.add_development_dependency 'minitest-heat', '~> 2.1'
  spec.add_development_dependency 'rdoc', '~> 7.1'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'simplecov_json_formatter', '~> 0.1'
  spec.add_development_dependency 'yard', '~> 0.9'
end

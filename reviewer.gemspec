# frozen_string_literal: true

require_relative 'lib/reviewer/version'

Gem::Specification.new do |spec|
  spec.name          = 'reviewer'
  spec.version       = Reviewer::VERSION
  spec.authors       = ['Garrett Dimon']
  spec.email         = ['email@garrettdimon.com']

  spec.summary       = 'Provides a unified approach to managing automated code quality tools.'
  spec.description   = 'Provides a unified approach to managing automated code quality tools.'
  spec.homepage      = 'https://github.com/garrettdimon/reviewer'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.9')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['bug_tracker_uri'] = 'https://github.com/garrettdimon/reviewer/issues'
  spec.metadata['changelog_uri'] = 'https://github.com/garrettdimon/reviewer/CHANGELOG.md'
  spec.metadata['documentation_uri'] = 'https://www.rubydoc.info/gems/reviewer'
  spec.metadata['source_code_uri'] = 'https://github.com/garrettdimon/reviewer'
  spec.metadata['wiki_uri'] = 'https://github.com/garrettdimon/reviewer/wiki'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'rainbow'
  spec.add_dependency 'slop'

  spec.add_development_dependency 'bundler-audit'
  spec.add_development_dependency 'codecov'
  spec.add_development_dependency 'flay'
  spec.add_development_dependency 'flog'
  spec.add_development_dependency 'inch'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'minitest-heat'
  spec.add_development_dependency 'psych'
  spec.add_development_dependency 'reek'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-minitest'
  spec.add_development_dependency 'rubocop-rake'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'yard'
end

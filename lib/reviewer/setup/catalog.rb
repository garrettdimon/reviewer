# frozen_string_literal: true

module Reviewer
  module Setup
    # Frozen hash of known tool definitions with detection signals.
    # Each entry contains the config structure needed for .reviewer.yml
    # plus a :detect key with signals for auto-detection.
    module Catalog
      # Known tool definitions with detection signals and default configuration
      TOOLS = {
        bundle_audit: {
          name: 'Bundle Audit',
          description: 'Review gem dependencies for security issues',
          tags: %w[security dependencies ruby],
          commands: {
            install: 'bundle exec gem install bundler-audit',
            prepare: 'bundle exec bundle-audit update',
            review: 'bundle exec bundle-audit check --no-update'
          },
          detect: {
            gems: %w[bundler-audit]
          }
        },
        rubocop: {
          name: 'RuboCop',
          description: 'Review Ruby syntax and formatting for consistency',
          tags: %w[ruby syntax],
          commands: {
            install: 'bundle exec gem install rubocop',
            review: 'bundle exec rubocop --parallel',
            format: 'bundle exec rubocop --auto-correct'
          },
          files: { flag: '', separator: ' ', pattern: '*.rb' },
          detect: {
            gems: %w[rubocop],
            files: %w[.rubocop.yml]
          }
        },
        standard: {
          name: 'Standard',
          description: 'Zero-configuration Ruby linter',
          tags: %w[ruby syntax],
          commands: {
            review: 'bundle exec standardrb',
            format: 'bundle exec standardrb --fix'
          },
          detect: {
            gems: %w[standard]
          }
        },
        reek: {
          name: 'Reek',
          description: 'Examine Ruby classes for code smells',
          tags: %w[ruby quality],
          commands: {
            install: 'bundle exec gem install reek',
            review: 'bundle exec reek'
          },
          files: { flag: '', separator: ' ', pattern: '*.rb' },
          detect: {
            gems: %w[reek],
            files: %w[.reek.yml]
          }
        },
        flog: {
          name: 'Flog',
          description: 'Reports the most tortured Ruby code in a pain report',
          tags: %w[ruby quality],
          commands: {
            install: 'bundle exec gem install flog',
            review: 'bundle exec flog -g lib'
          },
          detect: {
            gems: %w[flog]
          }
        },
        flay: {
          name: 'Flay',
          description: 'Review Ruby code for structural similarities',
          tags: %w[ruby quality],
          commands: {
            install: 'bundle exec gem install flay',
            review: 'bundle exec flay ./lib'
          },
          detect: {
            gems: %w[flay]
          }
        },
        brakeman: {
          name: 'Brakeman',
          description: 'Static analysis security scanner for Rails',
          tags: %w[security ruby],
          commands: {
            install: 'bundle exec gem install brakeman',
            review: 'bundle exec brakeman --no-pager -q'
          },
          detect: {
            gems: %w[brakeman],
            directories: %w[app/controllers]
          }
        },
        fasterer: {
          name: 'Fasterer',
          description: 'Suggest performance improvements for Ruby code',
          tags: %w[ruby quality performance],
          commands: {
            install: 'bundle exec gem install fasterer',
            review: 'bundle exec fasterer'
          },
          files: { flag: '', separator: ' ', pattern: '*.rb' },
          detect: {
            gems: %w[fasterer]
          }
        },
        tests: {
          name: 'Minitest',
          description: 'Unit tests and coverage',
          tags: %w[ruby tests],
          commands: {
            review: 'bundle exec rake test'
          },
          files: { review: 'bundle exec ruby -Itest', pattern: '*_test.rb', map_to_tests: 'minitest' },
          detect: {
            gems: %w[minitest],
            directories: %w[test]
          }
        },
        specs: {
          name: 'RSpec',
          description: 'Behavior-driven tests and coverage',
          tags: %w[ruby tests],
          commands: {
            review: 'bundle exec rspec'
          },
          files: { flag: '', separator: ' ', pattern: '*_spec.rb', map_to_tests: 'rspec' },
          detect: {
            gems: %w[rspec],
            directories: %w[spec]
          }
        },
        eslint: {
          name: 'ESLint',
          description: 'Lint JavaScript and TypeScript code',
          tags: %w[javascript linting syntax],
          commands: {
            review: 'npx eslint .',
            format: 'npx eslint . --fix'
          },
          files: { flag: '', separator: ' ', pattern: '*.js' },
          detect: {
            files: %w[.eslintrc .eslintrc.js .eslintrc.json .eslintrc.yml eslint.config.js eslint.config.mjs]
          }
        },
        prettier: {
          name: 'Prettier',
          description: 'Check code formatting consistency',
          tags: %w[javascript formatting],
          commands: {
            review: 'npx prettier --check .',
            format: 'npx prettier --write .'
          },
          detect: {
            files: %w[.prettierrc .prettierrc.js .prettierrc.json .prettierrc.yml .prettierrc.yaml]
          }
        },
        stylelint: {
          name: 'Stylelint',
          description: 'Lint CSS and SCSS for errors and consistency',
          tags: %w[css linting],
          commands: {
            review: 'npx stylelint "**/*.css"',
            format: 'npx stylelint "**/*.css" --fix'
          },
          files: { flag: '', separator: ' ', pattern: '*.css' },
          detect: {
            files: %w[.stylelintrc .stylelintrc.js .stylelintrc.json .stylelintrc.yml]
          }
        },
        typescript: {
          name: 'TypeScript',
          description: 'Type-check TypeScript code',
          tags: %w[javascript typescript],
          commands: {
            review: 'npx tsc --noEmit'
          },
          detect: {
            files: %w[tsconfig.json]
          }
        },
        biome: {
          name: 'Biome',
          description: 'Lint and format JavaScript and TypeScript',
          tags: %w[javascript linting formatting],
          commands: {
            review: 'npx @biomejs/biome check .',
            format: 'npx @biomejs/biome check . --fix'
          },
          files: { flag: '', separator: ' ', pattern: '*.js' },
          detect: {
            files: %w[biome.json biome.jsonc]
          }
        }
      }.freeze

      # Returns the full catalog of known tools
      #
      # @return [Hash] frozen hash of tool definitions
      def self.all = TOOLS

      # Returns the config for a tool key without the :detect key
      #
      # @param key [Symbol] the tool key
      # @return [Hash, nil] config hash without :detect, or nil if not found
      def self.config_for(key)
        definition = TOOLS[key]
        return nil unless definition

        definition.except(:detect)
      end

      # Returns the detection signals for a tool key
      #
      # @param key [Symbol] the tool key
      # @return [Hash, nil] detect hash, or nil if not found
      def self.detect_for(key)
        definition = TOOLS[key]
        return nil unless definition

        definition[:detect]
      end
    end
  end
end

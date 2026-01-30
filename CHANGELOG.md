## [Unreleased]

### Added
- Add `--capabilities` / `-c` flag for agent discovery (outputs JSON describing tools, keywords, scenarios)
- Add `--raw` / `-r` flag to force passthrough output (useful for CI/agent contexts)
- Add git keywords: `staged`, `unstaged`, `modified`, `untracked` for targeting files by git status
- Add `failed` keyword to re-run only tools that failed in the previous run, scoped to their failed files
- Add keyword resolution summary showing which tools and files will run before execution
- Add PTY-based streaming capture for passthrough runs, enabling failed file extraction from single-tool runs
- Add pattern-based file filtering via `files.pattern` config
- Add source-to-test file mapping via `files.map_to_tests` config
- Add expanded code review tools: fasterer, license_finder, notes (enabled); debride, brakeman, rubycritic, metric_fu, yardstick, standard, rufo (disabled)
- Add license_finder configuration with approved open source licenses

### Fixed
- Restore MIT license in LICENSE.txt to match gemspec declaration
- Fix `rvw failed` crash when `Arguments::Tags` object received `.empty?` instead of `.to_a.empty?`
- Fix `console_width` returning 0 in piped/CI contexts, falling back to default width

### Changed
- Confirm Ruby support for 3.2, 3.3, 3.4, and 4.0
- Upgrade CI Bundler from 2.6 to 2.7 to eliminate constant redefinition warnings on Ruby 3.4+
- Redesign passthrough output: replace "Now Running:" header and dividers with compact `↳ command` format
- Replace bold timing summary with `✓ ~Xs` checkmark format
- Rewrite README with installation, usage, and configuration documentation
- Apply fasterer performance suggestions (yield over block.call, fetch with block)

## [0.1.4] - 2021-07-08

On the surface, this release doesn't change much or provide drastically new functionality, but it begins to lay the foundation for something that could evolve in the long-term.

- Mostly refactoring to support the long-term vision
- Add Reek to dev dependencies
- Enable Inch in the default commands
- Reduce external dependencies
- Broaden official support Ruby 2.5.9, 2.6.8, 2.7.4, and 3.0.2
- Add more robust GitHub Actions integration
- Add Code Coverage via SimpleCov and set the bar at 100%
- Begin to expand documentation coverage
- Improve UX of results, timing, output, and error recovery guidance

## [0.1.3] - 2021-07-07

The most significant update to how the core commands work and how the command-line arguments are handled. Most of the overall structure is starting to feel stable enough to begin documenting and adding comments.

- Commands are now `rvw` and `fmt`
- Adds command-line arguments support
- Adds support for specifying tags via the command-line
- Adds support for specifying files via the command-line
- Adds support for handling keywords via the command-line
- Improved configuration and loading
- Adds Tools class for more convenient filtering of tools based on arguments
- Begins the process of adding documentation comments

## [0.1.2] - 2021-05-04

The bare minimum works now, but it's not quite there for day-to-day use. It works well enough that it's being used to review this project, but there's much more to do.

- Add Runner to wrap individual commands
- Add benchmark/timing to Runner
- Extract Logging to a dedicated class
- Intelligently handle non-zero exit statuses

## [0.1.1] - 2021-04-17

It doesn't work just yet, but it's filling out. Primarily, this enables it to parse the configuration file and turn each tool's settings into a runnable command string for install, prepare, review, and format.

- Added Configuration Management
- Added command-line framework with option parsing
- Created configuration loading bits
- Built pieces to generate complete command strings

## [0.1.0] - 2021-04-16

- Initial release

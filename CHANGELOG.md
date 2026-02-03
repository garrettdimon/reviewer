## [Unreleased]

## [1.0.0] - 2026-02-03

### Added
- Git-aware file targeting: `staged`, `unstaged`, `modified`, `untracked` keywords resolve files from git status and pass only relevant files to each tool
- `failed` keyword: re-run only tools that failed in the previous run, scoped to their failed files
- `--json` / `-j` flag for structured JSON output (CI, scripting, agent integration)
- `--raw` / `-r` flag to force passthrough output (bypasses capturing)
- `--format` flag with streaming, summary, and json modes
- `--capabilities` / `-c` flag for agent discovery (outputs JSON describing tools, keywords, scenarios)
- `skip_in_batch` config option: exclude tools from `rvw` while keeping them available via `rvw tool_name`
- `files.pattern` config: glob pattern to filter which files are passed to each tool
- `files.map_to_tests` config: map source files to test files (`minitest` or `rspec` conventions)
- `files.review` / `files.format` config: alternative commands when files are scoped
- First-run experience: interactive setup when no `.reviewer.yml` exists
- `rvw init` command: auto-detect tools from Gemfile.lock and generate `.reviewer.yml`
- `rvw doctor` command: diagnostics for configuration, tools, keywords, and environment
- Keyword resolution summary: preview which tools and files will run before execution
- Spell-check suggestions for mistyped keywords
- Auto-detection catalog: bundler-audit, rubocop, standard, reek, flog, flay, brakeman, fasterer, minitest, rspec, eslint, prettier, stylelint, typescript, biome
- Progress bar for captured output with timing estimates
- PTY-based streaming capture for failed file extraction from single-tool runs

### Fixed
- Console width returns default in piped/CI contexts instead of 0
- `rvw failed` no longer crashes on empty tag objects
- MIT license restored in LICENSE.txt
- `--help` and `--version` exit immediately instead of running tool suite
- Valid JSON emitted for early exits (no matching tools, no files)

### Changed
- **Ruby 3.2+ required** (supports 3.2, 3.3, 3.4, and 4.0)
- Architecture refactor: full dependency injection, no global state in business logic
- Output decomposed into domain formatters (Runner, Batch, Session, Doctor, Setup, Report)
- Session class owns run lifecycle; Reviewer module is pure wiring
- Context struct threads shared dependencies through the call stack
- Tool timing extracted to Tool::Timing collaborator with injected history
- Result interpretation separated from Runner execution (Result.from_runner)
- Tests no longer depend on global state or require reset between runs
- Redesigned output: compact `↳ command` format, `✓ ~Xs` checkmark summaries
- ANSI color output guarded for TTY (clean output in CI and pipes)
- README rewritten with installation, usage, configuration, and workflow documentation
- `disabled` config key deprecated in favor of `skip_in_batch`

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

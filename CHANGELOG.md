## [Unreleased]

- TODO: Standardize the commands and installation
- TODO: Add Targets to handle targeting specific files
- TODO: Add support for Targets in Tool/Command generator

## [0.1.2] - 2021-05-4

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

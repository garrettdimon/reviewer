# Contributing to Reviewer

Bug reports and pull requests are welcome on [GitHub](https://github.com/garrettdimon/reviewer).
Participation in the project follows the [Code of Conduct](../CODE_OF_CONDUCT.md).

## Project philosophy

- Reduce the friction of running multiple code-quality tools.
- Keep frequent reviews fast and their output focused.
- Preserve a project's commands and configuration instead of imposing tool policy.
- Make defaults simple while allowing each project to tune its workflow.
- Run tools in a predictable order and stop after an actionable failure.
- Report observations without turning Reviewer into a quality score.

## Development setup

Reviewer requires Ruby 3.2 or newer. Clone the repository, then install the development and dogfood
dependencies:

```console
bin/setup
```

Use `bin/console` for an interactive Ruby session. Run the local executable with `exe/rvw` when
exercising the CLI from the repository.

## Tests

Reviewer uses Minitest. Run only the test file covering the code you changed:

```console
bundle exec rvw tests -f test/reviewer/setup_test.rb
```

Write a failing test first, confirm the expected failure, make the minimum change, and rerun that
focused file. Prefer the fixtures under `test/fixtures/` to factories or ad hoc configuration data.

Before committing, use the repository's configured review gate on the staged changes:

```console
bundle exec rvw staged
```

## Pull requests

Keep each pull request to one logical change. Explain why the change is needed, include the focused
test evidence, and update user-facing documentation when behavior or configuration changes.

Do not mix release preparation into a feature or fix. Maintainers release Reviewer using the
[release guide](../RELEASING.md).

## API documentation

Public Ruby classes and methods are documented in the
[Reviewer API reference](https://www.rubydoc.info/gems/reviewer).

Return to the [documentation index](README.md).

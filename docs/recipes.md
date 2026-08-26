# Recipes

These examples are starting points. Copy only the tools a project uses, keep the commands the project
already trusts, and consult the [configuration reference](configuration.md) for composition rules.

Start with Doctor to see configured tools and sourced discoveries before choosing project commands:

```console
rvw doctor
```

## Focus tests on changed files

Use a file-scoped command and map Ruby source files to existing Minitest files:

```yaml
tests:
  name: Minitest
  tags: [ruby, tests]
  commands:
    review: bundle exec rake test
  files:
    review: bundle exec ruby -Itest
    pattern: "*_test.rb"
    map_to_tests: minitest
```

Then run:

```console
rvw tests staged
```

For RSpec, use `bundle exec rspec`, the pattern `*_spec.rb`, and `map_to_tests: rspec`.

## Review and format Ruby

Give a linter both review and format commands:

```yaml
rubocop:
  name: RuboCop
  tags: [ruby, syntax]
  commands:
    review: bundle exec rubocop --parallel
    format: bundle exec rubocop --auto-correct
  files:
    flag: ""
    separator: " "
    pattern: "*.rb"
```

Use `rvw rubocop` to inspect or `fmt rubocop staged` to format staged Ruby files.

## Keep a slow tool opt-in

Exclude an expensive check from the default batch without removing it:

```yaml
license_check:
  name: License check
  tags: [dependencies, compliance, slow]
  skip_in_batch: true
  commands:
    review: bundle exec license_finder
```

Run it explicitly with `rvw license_check`. Because `skip_in_batch` tools are excluded from tag
selection, the explicit key is also the reliable way to run one.

## Run a dependency audit first

YAML order is execution order, so put a dependency audit above tests and style checks when its
failure should stop the batch:

```yaml
bundle_audit:
  name: Bundle Audit
  tags: [ruby, dependencies, security]
  commands:
    prepare: bundle exec bundle-audit update
    review: bundle exec bundle-audit check --no-update

tests:
  name: Minitest
  tags: [ruby, tests]
  commands:
    review: bundle exec rake test
```

Return to the [documentation index](README.md).

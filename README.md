
**Note:** As of August 4th, 2021, Reviewer is a work in progress. While it's working great reviewing its own code, it's not quite ready for wider usage.

[![build](https://github.com/garrettdimon/reviewer/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/garrettdimon/reviewer/actions/workflows/main.yml)
[![coverage](https://img.shields.io/codecov/c/github/garrettdimon/reviewer?token=UuXUlQAA2e)](https://codecov.io/gh/garrettdimon/reviewer)
[![last commit](https://img.shields.io/github/last-commit/garrettdimon/reviewer/main)](https://github.com/garrettdimon/reviewer/commits/main)
[![gem version](https://img.shields.io/gem/v/reviewer)](https://rubygems.org/gems/reviewer)

# What is Reviewer?

*Reviewer reduces the friction of using multiple automated code review tools so you can use them more frequently and consistently.*

What if, instead of...

```bash
$ yarn audit --level moderate
$ bundle exec bundle-audit check --no-update
$ bundle exec rubocop --parallel
$ bundle exec erblint --lint-all --enable-all-linters
$ yarn stylelint .
$ yarn eslint .
```
...you could just type...
```
$ rvw
```

That's just the tip of the iceberg, though. For the full story on Reviewer's capabilities and benefits, the [Overview](https://github.com/garrettdimon/reviewer/wiki/Overview) is the best place to start. Or if you'd like to see how it's configured under the hood, the [Configuration Instructions](https://github.com/garrettdimon/reviewer/wiki/Configuration) go even deeper.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Reviewer project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/reviewer/blob/master/CODE_OF_CONDUCT.md).

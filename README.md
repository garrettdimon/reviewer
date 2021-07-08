**Note:** As of May 4th, 2021, Reviewer is a work in progress and does not actually do anything just yet. Hopefully soon.

# Reviewer

Reviewer reduces the friction of using automated tools for dependency audits, static analysis, linting, testing, and more by providing a standardized way to configure and run them in different contexts with less friction.

So, instead of...
```
yarn audit --level moderate
bundle exec bundle-audit check --no-update
bundle exec rubocop --parallel
bundle exec erblint --lint-all --enable-all-linters
yarn stylelint .
yarn eslint .
bundle exec rake notes
```

You run...
```
rvw
```

But that's just the beginning. It also cleans up the output and lets easily you run subsets of commands for different contexts.

For more detailed information, take a look at the [Overview](https://github.com/garrettdimon/reviewer/wiki/Overview) and [Usage](https://github.com/garrettdimon/reviewer/wiki/Usage) pages in the wiki.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'reviewer'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install reviewer

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/reviewer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/reviewer/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Reviewer project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/reviewer/blob/master/CODE_OF_CONDUCT.md).

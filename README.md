# Diagram

Diagram is a gem that allows you to create diagrams in Ruby.

The main features are:
 - Create diagrams in Ruby
 - Compare diagrams


## Installation

Add this line to your application's Gemfile:

```ruby 
gem 'diagram'
```

And then execute:

    $ bundle install

## Usage

```ruby
diagram = Diagrams::PieDiagram.new(
    title: 'My Pie Diagram',
    sections: [
        { label: 'A', value: 10 },
        { label: 'B', value: 20 },
        { label: 'C', value: 30 },
        { label: 'D', value: 40 },
    ]
)

diagram2 = Diagrams::PieDiagram.new(
    title: 'My Pie Diagram',
    sections: [
        { label: 'A', percentage: 10 },
        { label: 'B', percentage: 20 },
        { label: 'C', percentage: 30 },
        { label: 'D', percentage: 40 }
    ]
)
```
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/seuros/diagram-ruby.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

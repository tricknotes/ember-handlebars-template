# Ember::Handlebars::Template

The sprockets template for Ember Handlebars.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ember-handlebars-template'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install ember-handlebars-template
```

## Usage

``` ruby
Sprockets.register_engine '.hbs', Ember::Handlebars::Template # or other extension which you like.
```

## Options

You can overwrite config as the followings:

``` ruby
Ember::Handlebars::Template.configure do |config|
  config.precompile = true

  # You can overwrite other config
end
```

### precompile

Type: `Boolean`

Enables or disables precompilation.(default: `true`)

### ember_template

Type: `String`

Default which Ember template type to compile. `HTMLBars` / `Handlebars`. (default: `HTMLBars`)

### output_type

Type: `Symbol`

Configures the style of output. `:global` / `:amd`. (default `:global`)

### amd_namespace

Type: `String`

Configures the module prefix for AMD formatted output. (default: `nil`)

### templates_root

Type: `String`

Sets the root path for templates to be looked up in. (default: `templates`)

### templates_path_separator

Type: `String`

The path separator to use for templates. (default: `/`)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

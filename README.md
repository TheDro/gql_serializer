# GqlSerializer

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/gql_serializer`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gql_serializer'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install gql_serializer

## Usage

Say you have a class User

```ruby
class User < ActiveRecord::Base
  def encoded_id
    "User-#{id}"
  end
end
```

and you retrieve a user from your database

```ruby
user = User.create(name: 'Test User', email: 'user@test.com')
```

You can run

```ruby
user.as_gql
```

which will produce the following output

```ruby
{
    "id"=>1,
    "name"=>"Test User",
    "email"=>"user@test.com"
}
```

If you want to specify certain fields, you can pass them in as strings

```ruby
user.as_gql('encoded_id')
```

which would produce the following output

```ruby
{
    "encoded_id"=>"TestUser-1"
}
```

## Configuration

### Case conversion

Configuring the serializer to its default behavior of no case conversion:

```ruby
GqlSerializer.configure do |config|
  config.case = GqlSerializer::Configuration::NONE_CASE
end
```

It also supports conversion to camel case:

```ruby
GqlSerializer.configure do |config|
  config.case = GqlSerializer::Configuration::CAMEL_CASE
end
```

Or snake case:
```ruby
GqlSerializer.configure do |config|
  config.case = GqlSerializer::Configuration::SNAKE_CASE
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/gql_serializer.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

# GqlSerializer

GqlSerializer is a gem that makes it easy to serialize ActiveRecord objects into json using a short syntax similar to GraphQL instead of the more verbose syntax used by the `as_json` method.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gql_serializer'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install gql_serializer

## Basic Usage

Say you have the following `User` class

```ruby
class User < ActiveRecord::Base
  attribute :email_address, :string
  attribute :name, :string
  def encoded_id
    "User-#{id}"
  end
end
```

and you create a user

```ruby
user = User.create(name: 'Test User', email_address: 'user@test.com')
```

You can call `as_gql` with no arguments to get:

```ruby
user.as_gql
=> {
  "id"=>1,
  "name"=>"Test User",
  "email_address"=>"user@test.com"
}
```

By default, all attributes are included in the serialized form but you can create you want with the right arguments and include methods. 

```ruby
user.as_gql('name encoded_id')
=> {
  "name" => "Test User",
  "encoded_id" => "User-1"
}
```

## Advanced Usage

Here's where the library becomes more powerful. The GraphQL-esque syntax allows for aliasing and digging into nested objects.

```ruby
class User < ActiveRecord::Base
  attribute :email_address, :string
  attribute :name, :string
  has_many :orders
  def encoded_id
    "User-#{id}"
  end
end

class Order < ActiveRecord::Base
  belongs_to :user
  attribute :total, :float
  attribute :placed_at, :date_time
end

user = User.create(name: 'Test User', email_address: 'user@test.com')
order = Order.create(user: user, total: 3.50, placed_at: DateTime.now)

user.as_gql('name orders')
=> {
  "name" => "Test User",
  "orders" => [{
    "id" => 1,
    "total" => 3.5,
    "placed_at" => "2020-12-23T08:30:00Z"
  }]
}

order.as_gql('user { email_address encoded_id:real_id }')
=> {
  "id" => 1,
  "total" => 3.5,
  "placed_at" => "2020-12-23T08:30:00Z",
  "user" => {
    "email_address" => "user@test.com",
    "real_id" => "User-1"
  }
}
```

It's also possible to automatically convert the case of the keys into either camel case or snake case. We recommend that you configure this globally (see Configuration section) but it can be done using an optional second argument.

```ruby
user.as_gql('email_address name:full_name', {case: GqlSerializer::Configuration::CAMEL_CASE})
=> {
  "emailAddress" => "user@test.com",
  "fullName" => "Test User"
}
```

## Configuration

In a Rails application, the configuration can be added to an initializer in `config/initalizers/gql_serializer.rb`. The following is the default configuration (no change):

```ruby
GqlSerializer.configure do |config|
  # no case conversion
  config.case = GqlSerializer::Configuration::NONE_CASE 
  # set to true to avoid additional query in some cases. 
  # The default of false avoids a potential breaking change from version 2.1 to 2.2
  config.preload = false 
end
```

The options for `case` are: `NONE_CASE, CAMEL_CASE, SNAKE_CASE`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/TheDro/gql_serializer.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

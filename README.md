# LightMapper

This is simple mapper for hash.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'light_mapper'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install light_mapper

## Usage

### Basic usage

```ruby
{
  'FirstName' => 'Pawel',
  'LastName'  => 'Niemczyk'
}.extend(LightMapper).mapping(
  'FirstName' => :first_name,
  'LastName' => :last_name
)
```
result is obvious:

```ruby
{ first_name: 'Pawel', last_name: 'Niemczyk' }
```

The most popular usage:

```ruby
PersonMapper = {
  'FirstName' => :first_name,
  'LastName' => :last_name,
  'Age' => 'age'
}

data = {
  'FirstName' => 'Pawel',
  'LastName'  => 'Niemczyk',
  'Age' => 5
}

data.extend(LightMapper).mapping(PersonMapper)
```

### When you require all keys

```ruby
{
  'FirstName' => 'Pawel'
}.extend(LightMapper, require_keys: true).mapping(
  'FirstName' => :first_name,
  'LastName' => :last_name
)
```

it will raise KeyError

### When you want to pass string or symbol keys

```ruby
{
  'FirstName' => 'Pawel',
  second_name: 'Niemczyk'
}.extend(LightMapper, any_keys_kind: true).mapping(
  'FirstName' => :first_name,
  'second_name' => :last_name
)
```

result will be:

```ruby
{ first_name: 'Pawel', last_name: 'Niemczyk' }
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/light_mapper/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

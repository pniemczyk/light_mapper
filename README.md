# LightMapper

[![Gem Version](https://badge.fury.io/rb/light_mapper.svg)](http://badge.fury.io/rb/light_mapper)
[![Build Status](https://travis-ci.org/pniemczyk/light_mapper.svg?branch=master)](https://travis-ci.org/pniemczyk/light_mapper)

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

or

```ruby
LightMapper.mapping(
  { 'FirstName' => 'Pawel', 'LastName'  => 'Niemczyk' },
  { 'FirstName' => :first_name, 'LastName' => :last_name }
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
# {first_name: 'Pawel', last_name: 'Niemczyk', 'age': 5}
```

### When you require all keys

```ruby
{ 'FirstName' => 'Pawel' }.extend(LightMapper).mapping({'FirstName' => :first_name, 'LastName' => :last_name}, strict: true)
```

it will raise LightMapper::KeyMissing: LastName key not found; Full path LastName

### When you want to pass string or symbol keys

```ruby
{
  'FirstName' => 'Pawel',
  second_name: 'Niemczyk'
}.extend(LightMapper).mapping({
                                'FirstName' => :first_name,
                                'second_name' => :last_name
                              }, any_keys: true)
```

result will be:

```ruby
{ first_name: 'Pawel', last_name: 'Niemczyk' }
```

### Support for nested hashes, arrays and objects (now we talking what it is capable of)

```ruby
{
  'source' => { 'google' => { 'search_word' => 'ruby' } },
  'user' => User.new(email: 'pawel@example.com', name: 'Pawel'),
  'roles' => %w[admin manager user],
  'mixed' => { users: [User.new(email: 'max@example.com', name: 'Max', manager: true), User.new(email: 'pawel@example.com', name: 'Pawel', manager: false)] },
  'scores' => [ 10, 2, 5, 1000],
  'last_4_payments' => [
    { 'amount' => 100, 'currency' => 'USD' },
    { 'amount' => 200, 'currency' => 'USD' },
    { 'amount' => 300, 'currency' => 'USD' },
    { 'amount' => 400, 'currency' => 'USD' }
  ],
  'array' => [
    [1,2,3],
    [4,5,6],
    [
      7,
      8,
      [':D']
    ],
  ]
}.extend(LightMapper).mapping(
  'source.google.search_word' => :word,
  'user.email' => :email,
  'user.as_json.name' => :name,
  'roles.0' => :first_role,
  ['roles', 1] => :middle_role,
  'roles.last' => :last_role,
  (->(source) { source[:mixed][:users].find { |user| user.manager }.email }) => :manager_email,
  (->(source) { source[:mixed][:users].find { |user| user.manager }.name }) => :manager_name,
  'mixed.users.last.name' => :last_user_name,
  (->(source) { source[:last_4_payments].map(&:values).map(&:first).max }) => :quarterly_payment_amount,
  'scores.sum' => :final_score,
  'array.2.2.first' => :smile
)
```

result will be:

```ruby
{ 
  word: 'ruby', 
  email: 'pawel@example.com',
  name: 'Pawel',
  first_role: 'admin',
  last_role: 'user',
  manager_email: 'max@example.com',
  manager_name: 'Max',
  last_user_name: 'Pawel',
  quarterly_payment_amount: 1000,
  final_score: 1017
}
```

### Support for nested output structure and symbolize output keys

```ruby
{
  'source' => { 'google' => { 'private_pool' => true } },
  'user' => User.new(email: 'pawel@example.com', name: 'Pawel'),
  'roles' => %w[admin manager user],
  'scores' => [10, 2, 5, 1000],
  'last_4_payments' => [
    { 'amount' => 100, 'currency' => 'USD' },
    { 'amount' => 200, 'currency' => 'USD' },
    { 'amount' => 300, 'currency' => 'USD' },
    { 'amount' => 400, 'currency' => 'USD' }
  ]
}.extend(LightMapper).mapping({
  'source.google.private_pool' => 'private',
  'user.email' => 'user.email',
  'user.name' => 'user.name',
  'roles' => 'user.roles',
  'scores.max' => 'user.best_score',
  'last_4_payments.last' => 'payment.last',
}, keys: :symbol)
```

result will be: 

```ruby
{
  private: true,
  user: {
    email: 'pawel@example.com',
    name: 'Pawel',
    roles: %w[admin manager user],
    best_score: 1000,
  },
  payment: {
    last: { 'amount' => 400, 'currency' => 'USD' }
  }
}
```



### Mappers selection via pattern matching

```ruby
GOOGLE_MAPPER   = { 'result.user.name' => :name }
LINKEDIN_MAPPER = { 'result.client.display_name' => :word }

data = { source: 'google', user: { name: 'test'}, 'result' => { 'user' => { 'name' => 'Pawel'} } } 
mapper = case data
         in source: 'google', user: {name:} then GOOGLE_MAPPER
         in source: 'linkedin', client: {display_name:} then LINKEDIN_MAPPER
         else
           raise 'Unknown mapper'
         end

data.extend(LightMapper).mapping(mapper)
# result { name: 'Pawel' }
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/light_mapper/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

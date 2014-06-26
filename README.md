Hash Mash [ ![Codeship Status for deseretbook/hash_mash](https://www.codeship.io/projects/dd988da0-dee7-0131-9e92-7e1ff0bec112/status)](https://www.codeship.io/projects/24888)
=========

### Mash any Hash with a declarative data transformation DSL

Hash Mash provides a simple, Ruby Hash-based way of transforming data from one
format to another.  It's vaguely like XSLT, but way less complicated and way
more Ruby.  It can also help verify your transformations by validating input
and output data using [Classy Hash](https://github.com/deseretbook/classy_hash).

You specify Hash to Hash transformations using a Hash with a list of output
keys, input keys, and transformations, and Hash Mash will convert your data
into the format you specify.

### Examples

#### Simple example

Suppose your application receives Hash data in one format, but you need to pass
it along in another format.  You might need to rename some keys, convert some
keys to different types, merge keys, etc.  We'll define the input and output
data using [Classy Hash schemas](https://github.com/deseretbook/classy_hash#simple-example).

```ruby
# Classy Hash schema - https://github.com/deseretbook/classy_hash
in_schema = {
  # Totally violates http://www.kalzumeus.com/2010/06/17/falsehoods-programmers-believe-about-names/
  first: String,
  last: String,
  city: String,
  phone: String,
}

out_schema = {
  name: String,
  location: String,
  phone: Integer, # Just for example; probably shouldn't make phone numbers integers
}
```

You can write a Hash Mash transformation to turn any Hash with the `in_schema`
format into a Hash with the `out_schema` format.

```ruby
# Hash Mash transformation - https://github.com/deseretbook/hash_mash
xform = {
  # Combine first and last name into a single String
  name: lambda {|data| "#{data[:first]} #{data[:last]}".strip },

  # Copy the :city field directly into :location
  location: :city,

  # Remove non-digits from :phone
  phone: lambda {|data| data[:phone].gsub(/[^\d]/, '').to_i }
}

data = {
  first: 'Hash',
  last: 'Mash',
  city: 'Here',
  phone: '555-555-5555',
}

HashMash.transform(data, xform) # Returns {name: 'Hash Mash', location: 'Here', phone: 5555555555}
```

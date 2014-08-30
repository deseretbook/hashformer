Hashformer
=========
[![Gem Version](https://badge.fury.io/rb/hashformer.svg)](http://badge.fury.io/rb/hashformer) [![Code Climate](https://codeclimate.com/github/deseretbook/hashformer.png)](https://codeclimate.com/github/deseretbook/hashformer) [![Test Coverage](https://codeclimate.com/github/deseretbook/hashformer/coverage.png)](https://codeclimate.com/github/deseretbook/hashformer) [![Codeship Status for deseretbook/hashformer](https://www.codeship.io/projects/dd988da0-dee7-0131-9e92-7e1ff0bec112/status?branch=master)](https://www.codeship.io/projects/24888)

### Transform any Ruby Hash with a declarative DSL

Hashformer is the ultimate Ruby Hash transformation tool, made from 100% pure
Hashformium (may contain trace amounts of caffeine).  It provides a simple,
Ruby Hash-based DSL for transforming data from one format to another.  It's
vaguely like XSLT, but way less complicated and way more Ruby.

You specify Hash to Hash transformations using a Hash with a list of output
keys, input keys, and transformations, and Hashformer will convert your data
into the format you specify.  It can also help verify your transformations by
validating input and output data using [Classy Hash](https://github.com/deseretbook/classy_hash).


### Examples

#### Basic renaming

If you just need to move/copy/rename keys, you specify the source key as the
value for the destination key in your transformation:

```ruby
data = {
  'first_name' => 'Hash',
  'last_name' => 'Former'
}
xform = {
  first: 'first_name',
  last: 'last_name'
}

Hashformer.transform(data, xform)
# => {first: 'Hash', last: 'Former'}
```

Just about any source key type will work:

```ruby
data = {
  0 => 'Nothing',
  1 => 'Only One'
}
xform = {
  zero: 0,
  one: 1
}

Hashformer.transform(data, xform)
# => {zero: 'Nothing', one: 'Only One'}
```


#### Nested *input* values

If you need to grab values from a Hash or Array within a Hash, you can use
`Hashformer::Generate.path` (or, the convenient shortcut, `HF::G.path`):

```ruby
data = {
  name: 'Hashformer',
  addresses: [
    {
      line1: 'Hash',
      line2: 'Former'
    }
  ]
}
xform = {
  name: :name,
  line1: HF::G.path[:addresses][0][:line1],
  line2: HF::G.path[:addresses][0][:line2]
}

Hashformer.transform(data, xform)
# => {name: 'Hashformer', line1: 'Hash', line2: 'Former'}
```

If you try to access beyond a path that doesn't exist, nil will be returned
instead:

```ruby
data = {
  a: { b: 'c' }
}
xform = {
  a: HF::G.path[:a][0][:c]
}

Hashformer.transform(data, xform)
# => {a: nil}
```

If no path is specified, the entire Hash will be returned:

```ruby
data = {
  a: 1,
  b: 2
}
xform = {
  h: HF::G.path
}

Hashformer.transform(data, xform)
# => {h: {a: 1, b: 2}}
```


#### Constant values

If you need to specify a constant value in your output Hash in version 0.2.2 or
later, use `HF::G.const()`:

```ruby
data = {
  irrelevant: 'data',
}
xform = {
  data: HF::G.const(:irrelevant)
}

Hashformer.transform(data, xform)
# => {data: :irrelevant}
```

Most types will work with `HF::G.const()`:

```ruby
data = {
}
xform = {
  out: HF::G.const({a: 1, b: 2, c: [3, 4, 5]})
}

Hashformer.transform(data, xform)
# => {out: {a: 1, b: 2, c: [3, 4, 5]}}
```


#### Method chaining

This is the most useful and powerful aspect of Hashformer.  You can use
`HF::G.chain`, or the shortcut `HF[]`, to chain method calls and Array or Hash
lookups:

_**Note:** Method chaining may not work as expected if entered in `irb`, because
`irb` might try to call `#to_s` or `#inspect` on the method chain!_

```ruby
data = {
  s: 'Hashformer',
  v: [1, 2, 3, 4, 5]
}
xform = {
  s: HF[:s].reverse.capitalize,
  # It's important to call clone before calling methods that modify the array
  v: HF[:v].clone.concat([6]).map{|x| x * x}.reduce(0, &:+)
}

Hashformer.transform(data, xform)
# => {s: 'Remrofhsah', v: 91}
```

Unlike `HF::g.path`, `HF[]`/`HF::G.chain` will raise an exception if you try to
access beyond a path that doesn't exist:

```ruby
data = {
  a: [1, 2, 3]
}
xform = {
  a: HF[:b][0]
}

Hashformer.transform(data, xform)
# Raises "undefined method `[]' for nil:NilClass"
```

`HF[]` or `HF::G.chain` without any methods or references will return the input
Hash:

```ruby
data = {
  a: 1
}
xform = {
  a: HF[].count,
  b: HF::G.chain
}

Hashformer.transform(data, xform)
# => {a: 1, b: {a: 1}}
```

Although it's not recommended, you can also chain operators as long as `HF[]`
is the first element evaluated by Ruby:

```ruby
xform = {
  x: -(HF[:x] * 2) + 5
}

Hashformer.transform({x: 3}, xform)
# => {x: -1}

Hashformer.transform({x: -12}, xform)
# => {x: 29}
```


#### Mapping one or more values

If you want Hashformer to gather one or more values for you and either place
them in an Array or pass them to a lambda, you can use `HF::G.map`.  Pass the
names of the keys to map as parameters, followed by the optional Proc or
lambda:

```ruby
data = {
  a: 'Hashformer'
}
xform = {
  a: HF::G.map(:a, &:upcase),
  b: HF::G.map(:a)
}

Hashformer.transform(data, xform)
# => {a: 'HASHFORMER', b: ['Hashformer']}
```

You can also mix and match paths and method chains in the `HF::G.map`
parameters:

```ruby
data = {
  items: [
    {name: 'Item 1', price: 1.50},
    {name: 'Item 2', price: 2.50},
    {name: 'Item 3', price: 3.50},
    {name: 'Item 4', price: 4.50},
  ],
  shipping: 5.50
}
xform = {
  item_total: HF[:items].map{|i| i[:price]}.reduce(0.0, &:+),
  total: HF::G.map(HF[:items].map{|i| i[:price]}.reduce(0.0, &:+), HF::G.path[:shipping], &:+)
}

Hashformer.transform(data, xform)
# => {item_total: 12.0, total: 17.5}
```


#### Lambda processing

If you need to apply a completely custom transformation to your data, you can
use a raw lambda.  The lambda will be called with the entire input Hash.

```ruby
data = {
  x: 3.0,
  y: 4.0
}
xform = {
  radius: ->(h){ Math.sqrt(h[:x] * h[:x] + h[:y] * h[:y]) }
}

Hashformer.transform(data, xform)
# => {radius: 5.0}
```


#### Dynamic key names

There might not be much use for it, but you can use a lambda as a key as well.
It will be called with its associated unprocessed value and the input Hash:

```ruby
data = {
  key: :x,
  value: 0
}
xform = {
  ->(value, h){h[:key]} => :value
}

Hashformer.transform(data, xform)
# => {x: 0}
```


#### Nested *output* values

As of Hashformer 0.2.2, you can also nest transformations within
transformations to generate a Hash for an output value:

```ruby
data = {
  a: 1,
  b: 2,
  c: 3
}
xform = {
  a: {
    all: ->(orig){ orig },
  },
  b: {
    x: :a,
    y: :b,
    z: :c,
  }
}

Hashformer.transform(data, xform)
# => {a: { all: { a: 1, b: 2, c: 3 } }, b: { x: 1, y: 2, z: 3 }}
```

Nested transformations will still refer to the original input Hash, rather than
any input key of the same name.  That way any value from the input can be used
at any point in the output:

```ruby
data = {
  a: 1,
  b: {
    a: 2,
    b: 3,
    c: 4
  },
  c: 5
}
xform = {
  b: {
    n: :a,             # Refers to the top-level :a
    o: HF[:b][:a],     # Refers to the :a within :b
    p: ->(h){ h[:c] }, # Refers to the top-level :c
  }
}

Hashformer.transform(data, xform)
# => {b: { n: 1, o: 2, p: 5 }}
```


#### Practical example with validation

Suppose your application receives addresses in one format, but you need to pass
them along in another format.  You might need to rename some keys, convert some
keys to different types, merge keys, etc.  We'll define the input and output
data formats using [Classy Hash schemas](https://github.com/deseretbook/classy_hash#simple-example).

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

You can write a Hashformer transformation to turn any Hash with the `in_schema`
format into a Hash with the `out_schema` format, and verify the results:

```ruby
# Hashformer transformation - https://github.com/deseretbook/hashformer
xform = {
  # Validate input and output data according to the Classy Hash schemas
  __in_schema: in_schema,
  __out_schema: out_schema,

  # Combine first and last name into a single String
  name: HF::G.map(:first, :last) {|f, l| "#{f} #{l}".strip},

  # Copy the :city field directly into :location
  location: :city,

  # Remove non-digits from :phone
  phone: HF[:phone].gsub(/[^\d]/, '').to_i
}

data = {
  first: 'Hash',
  last: 'Transformed',
  city: 'Here',
  phone: '555-555-5555',
}

Hashformer.transform(data, xform)
# => {name: 'Hash Transformed', location: 'Here', phone: 5555555555}
```


### Testing

Hashformer includes a thorough [RSpec](http://rspec.info) test suite:

```bash
# Execute within a clone of the Git repository:
bundle install --without=development
rspec
```


### Alternatives

Hashformer just might be the coolest Ruby Hash data transformer out there.  But
if you disagree, here are some other options:

- [hash_transformer](https://github.com/trampoline/hash_transformer) provides
  an *imperative* DSL for Hash modification.
- [ActiveModel::Serializers](https://github.com/rails-api/active_model_serializers)
- [XSLT](https://en.wikipedia.org/wiki/Xslt)


### License

Hashformer is released under the MIT license (see the `LICENSE` file for the
license text and copyright notice).

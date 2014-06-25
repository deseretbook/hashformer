# Hash Mash: A declarative data transformation DSL
# Created June 2014 by Mike Bourgeous, DeseretBook.com
# Copyright (C)2014 Deseret Book
# See LICENSE and README.md for details.

require 'hash_mash'

RSpec.describe HashMash do
  describe '.validate' do
    it 'processes simple transformations' do
      expect(HashMash.transform({a: 1}, {b: :a})).to eq({b: 1})
      expect(HashMash.transform({a: 1, b: 2}, {b: :a, a: :b})).to eq({a: 2, b: 1})
    end

    it 'processes simple lambda transformations' do
      expect(HashMash.transform({a: 1}, {a: ->(x){-x[:a]}})).to eq({a: -1})
      expect(HashMash.transform({a: 'hello'}, {a: ->(x){x[:a].length}})).to eq({a: 5})
    end

    it 'processes multi-value lambda transformations' do
      expect(HashMash.transform({a: 'hello', b: 'world'}, {c: ->(x){"#{x[:a].capitalize} #{x[:b]}"}})).to eq({c: 'Hello world'})
      expect(HashMash.transform({a: 1, b: 2, c: 3}, {sum: ->(x){x.values.reduce(&:+)}})).to eq({sum: 6})
    end

    # TODO
    pending 'processes lambda keys'
    pending 'handles missing input keys'
    pending 'handles strings as key names'
    pending 'does not pass values not specified in transformation'

    context 'input schema is given' do
      pending 'accepts valid input hashes'
      pending' rejects invalid input hashes'
    end

    context 'output schema is given' do
      pending 'accepts valid output hashes'
      pending 'rejects invalid output hashes'
    end
  end
end

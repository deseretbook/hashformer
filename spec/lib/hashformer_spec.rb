# Hashformer: A declarative data transformation DSL for Ruby -- test suite
# Created June 2014 by Mike Bourgeous, DeseretBook.com
# Copyright (C)2014 Deseret Book
# See LICENSE and README.md for details.

require 'spec_helper'

require 'hashformer'

RSpec.describe Hashformer do
  describe '.validate' do
    let(:in_schema) {
      # ClassyHash schema - https://github.com/deseretbook/classy_hash
      {
        first: String,
        last: String,
        city: [:optional, String],
        phone: String
      }
    }

    let(:out_schema) {
      # ClassyHash schema - https://github.com/deseretbook/classy_hash
      {
        name: String,
        location: String,
        phone: Integer
      }
    }

    it 'processes simple transformations' do
      expect(Hashformer.transform({}, {})).to eq({})
      expect(Hashformer.transform({a: 1}, {b: :a})).to eq({b: 1})
      expect(Hashformer.transform({a: 1, b: 2}, {b: :a, a: :b})).to eq({a: 2, b: 1})
    end

    it 'processes simple lambda transformations' do
      expect(Hashformer.transform({a: 1}, {a: ->(x){-x[:a]}})).to eq({a: -1})
      expect(Hashformer.transform({a: 'hello'}, {a: ->(x){x[:a].length}})).to eq({a: 5})
    end

    it 'processes multi-value lambda transformations' do
      expect(Hashformer.transform({a: 'hello', b: 'world'}, {c: ->(x){"#{x[:a].capitalize} #{x[:b]}"}})).to eq({c: 'Hello world'})
      expect(Hashformer.transform({a: 1, b: 2, c: 3}, {sum: ->(x){x.values.reduce(&:+)}})).to eq({sum: 6})
    end

    it 'processes lambda keys' do
      keyindex = {
        ->(value, data){ "key#{data.keys.index(value)}".to_sym } => :x
      }

      expect(Hashformer.transform({x: 0}, keyindex)).to eq({key0: 0})
      expect(Hashformer.transform({a: 2, b: 1, x: 0}, keyindex)).to eq({key2: 0})

      keyvaluejoin = {
        ->(value, data){ data[:key] } => :value
      }

      expect(Hashformer.transform({key: :x, value: -3}, keyvaluejoin)).to eq({x: -3})
    end

    it 'handles missing input keys' do
      expect(Hashformer.transform({}, {a: :a})).to eq({a: nil})
      expect(Hashformer.transform({a: 1}, {a: :a, b: :b, c: :c})).to eq({a: 1, b: nil, c: nil})
    end
    
    it 'does not pass values not specified in transformation' do
      expect(Hashformer.transform({a: 1}, {})).to eq({})
      expect(Hashformer.transform({a: 1, b: 2, c: 3}, {x: :c})).to eq({x: 3})
    end

    it 'handles strings as key names' do
      expect(Hashformer.transform({}, {'a' => :a})).to eq({'a' => nil})
      expect(Hashformer.transform({a: 1}, {'a' => :a})).to eq({'a' => 1})
      expect(Hashformer.transform({'a' => 1, 'b' => 2}, {'b' => 'a', 'a' => 'b'})).to eq({'a' => 2, 'b' => 1})
    end

    context 'input schema is given' do
      let(:xform) {
        {
          __in_schema: in_schema
        }
      }

      it 'accepts valid input hashes' do
        expect {
          Hashformer.transform({first: 'Hello', last: 'World', city: 'Here', phone: '1-2-3-4-5'}, xform)
        }.not_to raise_error
      end

      context 'validate is true' do
        it 'rejects invalid input hashes' do
          expect {
            Hashformer.transform({}, xform)
          }.to raise_error(/present/)

          expect {
            Hashformer.transform({first: :last}, xform)
          }.to raise_error(/first/)
        end
      end

      context 'validate is false' do
        it 'accepts invalid input hashes' do
          expect {
            Hashformer.transform({}, xform, false)
          }.not_to raise_error
        end
      end
    end

    context 'output schema is given' do
      let(:xform) {
        {
          __out_schema: out_schema,

          name: lambda {|data| "#{data[:first]} #{data[:last]}".strip },
          location: :city,
          phone: lambda {|data| data[:phone].gsub(/[^\d]/, '').to_i }
        }
      }

      it 'accepts valid output hashes' do
        expect {
          Hashformer.transform({city: '', phone: ''}, xform)
        }.not_to raise_error
      end

      context 'validate is true' do
        it 'rejects invalid output hashes' do
          expect {
            Hashformer.transform({city: 17, phone: ''}, xform)
          }.to raise_error(/location/)
        end
      end

      context 'validate is false' do
        it 'accepts invalid output hashes' do
          expect {
            Hashformer.transform({city: 17, phone: ''}, xform, false)
          }.not_to raise_error
        end
      end
    end

    context 'both input and output schema are given' do
      let(:xform) {
        {
          __in_schema: in_schema,
          __out_schema: out_schema,

          name: lambda {|data| "#{data[:first]} #{data[:last]}".strip },
          location: :city,
          phone: lambda {|data| data[:phone].gsub(/[^\d]/, '').to_i }
        }
      }

      it 'transforms valid data correctly' do
        expect(Hashformer.transform(
          {
            first: 'Hash',
            last: 'Transformed',
            city: 'Here',
            phone: '555-555-5555'
          },
          xform
        )).to eq({name: 'Hash Transformed', location: 'Here', phone: 5555555555})
      end

      it 'rejects invalid input' do
        expect{
          Hashformer.transform({}, xform)
        }.to raise_error(/present/)
      end

      it 'rejects invalid output' do
        expect{
          Hashformer.transform({first: 'Hello', last: 'There', phone: '555-555-5555'}, xform)
        }.to raise_error(/output data failed/)
      end
    end
  end
end

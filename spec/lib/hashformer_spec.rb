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

    context 'README examples' do
      context 'Basic renaming' do
        it 'produces the expected output for string keys' do
          data = {
            'first_name' => 'Hash',
            'last_name' => 'Former'
          }
          xform = {
            first: 'first_name',
            last: 'last_name'
          }

          expect(Hashformer.transform(data, xform)).to eq({first: 'Hash', last: 'Former'})
        end

        it 'produces the expected output for integer keys' do
          data = {
            0 => 'Nothing',
            1 => 'Only One'
          }
          xform = {
            zero: 0,
            one: 1
          }

          expect(Hashformer.transform(data, xform)).to eq({zero: 'Nothing', one: 'Only One'})
        end
      end

      context 'Nested input values' do
        it 'produces the expected output for a present path' do
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

          expect(Hashformer.transform(data, xform)).to eq({name: 'Hashformer', line1: 'Hash', line2: 'Former'})
        end

        it 'produces the expected output for a missing path' do
          data = {
            a: { b: 'c' }
          }
          xform = {
            a: HF::G.path[:a][0][:c]
          }

          expect(Hashformer.transform(data, xform)).to eq({a: nil})
        end

        it 'returns the entire hash if no path is given' do
          data = {
            a: 1,
            b: 2
          }
          xform = {
            h: HF::G.path
          }

          expect(Hashformer.transform(data, xform)).to eq({h: {a: 1, b: 2}})
        end
      end

      context 'Constant values' do
        it 'produces the expected output for a symbol' do
          data = {
            irrelevant: 'data',
          }
          xform = {
            data: HF::G.const(:irrelevant)
          }

          expect(Hashformer.transform(data, xform)).to eq({data: :irrelevant})
        end

        it 'produces the expected output for a hash' do
          data = {
          }
          xform = {
            out: HF::G.const({a: 1, b: 2, c: [3, 4, 5]})
          }

          expect(Hashformer.transform(data, xform)).to eq({out: {a: 1, b: 2, c: [3, 4, 5]}})
        end
      end

      context 'Method chaining' do
        it 'produces the expected output for simple method chaining' do
          data = {
            s: 'Hashformer',
            v: [1, 2, 3, 4, 5]
          }
          xform = {
            s: HF[:s].reverse.capitalize,
            # It's important to call clone before calling methods that modify the array
            v: HF[:v].clone.concat([6]).map{|x| x * x}.reduce(0, &:+)
          }

          expect(Hashformer.transform(data, xform)).to eq({s: 'Remrofhsah', v: 91})
        end

        it 'raises an exception if accessing beyond a missing path' do
          data = {
            a: [1, 2, 3]
          }
          xform = {
            a: HF[:b][0]
          }

          expect{Hashformer.transform(data, xform)}.to raise_error(/\[\]/)
        end

        it 'returns the input hash with no methods added' do
          data = {
            a: 1
          }
          xform = {
            a: HF[].count,
            b: HF::G.chain
          }

          expect(Hashformer.transform(data, xform)).to eq({a: 1, b: {a: 1}})
        end

        it 'produces the expected output for chained operators' do
          xform = {
            x: -(HF[:x] * 2) + 5
          }

          expect(Hashformer.transform({x: 3}, xform)).to eq({x: -1})
          expect(Hashformer.transform({x: -12}, xform)).to eq({x: 29})
        end
      end

      context 'Mapping one or more values' do
        it 'produces the expected output for a single map parameter' do
          data = {
            a: 'Hashformer'
          }
          xform = {
            a: HF::G.map(:a, &:upcase),
            b: HF::G.map(:a)
          }

          expect(Hashformer.transform(data, xform)).to eq({a: 'HASHFORMER', b: ['Hashformer']})
        end

        it 'produces the expected output for a map/reduce' do
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

          expect(Hashformer.transform(data, xform)).to eq({item_total: 12.0, total: 17.5})
        end
      end

      context 'Lambda processing' do
        it 'produces the expected output for the Pythagorean distance equation' do
          data = {
            x: 3.0,
            y: 4.0
          }
          xform = {
            radius: ->(h){ Math.sqrt(h[:x] * h[:x] + h[:y] * h[:y]) }
          }

          expect(Hashformer.transform(data, xform)).to eq({radius: 5.0})
        end
      end

      context 'Dynamic key names' do
        it 'produces the expected output for a dynamic key' do
          data = {
            key: :x,
            value: 0
          }
          xform = {
            ->(value, h){h[:key]} => :value
          }

          expect(Hashformer.transform(data, xform)).to eq({x: 0})
        end
      end

      context 'Nested output values' do
        it 'produces the expected output for a flat input' do
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
          expected = {
            a: { all: { a: 1, b: 2, c: 3 } },
            b: { x: 1, y: 2, z: 3 }
          }

          expect(Hashformer.transform(data, xform)).to eq(expected)
        end

        it 'produces the expected output for a nested input' do
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
          expected = {b: { n: 1, o: 2, p: 5 }}

          expect(Hashformer.transform(data, xform)).to eq(expected)
        end
      end

      context 'Practical example with validation' do
        it 'produces the expected output for a practical example' do
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

          expected = {name: 'Hash Transformed', location: 'Here', phone: 5555555555}

          expect(Hashformer.transform(data, xform)).to eq(expected)
        end
      end

      context 'Nested transformations' do
        it 'produces the expected output for a practical example' do
          in_schema = {
            name: {
              first: String,
              last: String,
            },

            email: String,
            phone: String,

            address: {
              line1: String,
              line2: String,
              city: String,
              state: String,
              zip: String,
            }
          }

          out_schema = {
            first: String,
            last: String,
            email: String,

            address: {
              phone: String,
              lines: {
                line1: String,
                line2: String,
              },
              city: String,
              state: String,
              postcode: String,
            }
          }

          xform = {
            # Using multiple different transform types to make sure they all
            # work here.  Normally one would use HF[] for all of these.
            first: HF[:name][:first],
            last: HF::G.path[:name][:last],
            email: HF::G.map(:email){|e| e},

            address: {
              phone: :phone,
              lines: {
                line1: ->(u){ u[:address][:line1] },
                line2: HF[:address][:line2],
              },
              city: HF[:address][:city],
              state: HF::G.path[:address][:state],
              postcode: HF[:address][:zip],
            }
          }

          data = {
            name: {
              first: 'Hash',
              last: 'Transformed',
            },

            email: 'Hashformer@example',
            phone: '555-555-5555',

            address: {
              line1: '123 This Street',
              line2: 'That One There',
              city: 'Here',
              state: 'ZZ',
              zip: '00000',
            }
          }

          expected = {
            first: 'Hash',
            last: 'Transformed',
            email: 'Hashformer@example',

            address: {
              phone: '555-555-5555',
              lines: {
                line1: '123 This Street',
                line2: 'That One There',
              },
              city: 'Here',
              state: 'ZZ',
              postcode: '00000',
            }
          }

          expect(Hashformer.transform(data, xform)).to eq(expected)
        end
      end
    end
  end
end

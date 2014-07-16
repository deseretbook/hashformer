# Hashformer transformation generator tests
# Created July 2014 by Mike Bourgeous, DeseretBook.com
# Copyright (C)2014 Deseret Book
# See LICENSE and README.md for details.

require 'spec_helper'

require 'hashformer'

RSpec.describe Hashformer::Generate do
  describe '.map' do
    let(:data) {
      {
        first: 'Hash',
        last: 'Former'
      }
    }

    context 'map was given no arguments' do
      context 'map was not given a block' do
        it 'returns an empty array' do
          expect(Hashformer.transform(data, { out: HF::G.map() })).to eq({out: []})
        end
      end

      context 'map was given a block' do
        it 'passes no arguments to the block' do
          expect(Hashformer.transform(data, { out: HF::G.map(){|*a| a.count} })).to eq({out: 0})
        end
      end
    end

    context 'map was not given a block' do
      let(:xform) {
        {
          name: HF::G.map(:first, :last),
          first: HF::G.map(:first),
          last: HF::G.map(:last)
        }
      }

      it 'stores mapped values into an array' do
        expect(Hashformer.transform(data, xform)).to eq({name: ['Hash', 'Former'], first: ['Hash'], last: ['Former']})
      end

      it 'adds nil to a returned array for missing keys' do
        expect(Hashformer.transform({}, xform)).to eq({name: [nil, nil], first: [nil], last: [nil]})
      end
    end

    context 'map was given a block that returns a string' do
      let(:xform) {
        {
          name: HF::G.map(:first, :last) { |f, l| "#{f} #{l}".strip }
        }
      }

      it 'generates the expected string for missing keys' do
        expect(Hashformer.transform({}, xform)).to eq({name: ''})
      end

      it 'generates the expected string' do
        expect(Hashformer.transform(data, xform)).to eq({name: 'Hash Former'})
      end
    end

    context 'map was given a block that returns a reversed array' do
      let(:xform) {
        {
          name: HF::G.map(:first, :last) { |*a| a.reverse }
        }
      }

      it 'passes nil for missing keys' do
        expect(Hashformer.transform({}, xform)).to eq({name: [nil, nil]})
      end

      it 'generates the expected array' do
        expect(Hashformer.transform(data, xform)).to eq({name: ['Former', 'Hash']})
      end
    end

    context 'map was given callables as keys and no block' do
      let(:xform) {
        {
          name: HF::G.map(->(h){h[:first]}, ->(h){h[:last]})
        }
      }

      it 'generates the expected output array' do
        expect(Hashformer.transform(data, xform)).to eq({name: ['Hash', 'Former']})
      end
    end

    context 'map was given paths as keys' do
      let(:xform) {
        {
          name: HF::G.map(HF::G.path[:first], HF::G.path[:last]) { |*a| a.join(' ').downcase }
        }
      }

      it 'generates the expected output' do
        expect(Hashformer.transform(data, xform)).to eq({name: 'hash former'})
      end
    end

    context 'map was given method chains as keys and no block' do
      let(:xform) {
        {
          name: HF::G.map(HF::G.chain[:first].downcase, HF::G.chain[:last].upcase)
        }
      }

      it 'generates the expected output' do
        expect(Hashformer.transform(data, xform)).to eq({name: ['hash', 'FORMER']})
      end
    end

    it 'works when chained' do
      xform = {
        name: HF::G.map(HF::G.map(:first, :last), HF::G.map(:last, :first))
      }

      expect(Hashformer.transform(data, xform)).to eq({name: [['Hash', 'Former'], ['Former', 'Hash']]})
    end

    it 'joins an array using a method reference' do
      data = { a: [1, 2, 3, 4] }
      xform = { a: HF::G.map(:a, &:join) }
      expect(Hashformer.transform(data, xform)).to eq({a: '1234'})
    end
  end

  describe '.path' do
    let(:data) {
      {
        a: { b: [ 'c', 'd', 'e', 'f' ] }
      }
    }

    let(:xform) {
      {
        a: HF::G.path[:a][:b][0],
        b: HF::G.path[:a][:b][3]
      }
    }

    it 'produces the expected output for a simple input' do
      expect(Hashformer.transform(data, xform)).to eq({a: 'c', b: 'f'})
    end

    it 'returns nil when dereferencing a nonexistent path' do
      expect(Hashformer.transform(data, {a: HF::G.path[:b][:c][0][1][2][3]})).to eq({a: nil})
    end

    it 'raises an error when dereferencing a non-array/non-hash object' do
      expect{Hashformer.transform(data, {a: HF::G.path[:a][:b][0][:fail]})}.to raise_error(/dereferencing/)
    end

    context 'no path is added' do
      it 'returns the input hash' do
        expect(Hashformer.transform({a: 1, b: 2}, {x: HF::G.path})).to eq({x: {a: 1, b: 2}})
      end
    end
  end

  describe '.chain' do
    let(:data) {
      {
        in1: {
          in1: ['a', 'b', 'c', 'd'],
          in2: [1, 2, 3, [4, 5, 6, 7]]
        }
      }
    }

    let(:xform) {
       xform = {
         out1: HF::G.chain[:in1][:in2][3].reduce(&:+),
         out2: HF[:in1][:in1][3],
         out3: HF[].count
       }
    }

    it 'produces the expected output for a simple input' do
      expect(Hashformer.transform(data, xform)).to eq({out1: 22, out2: 'd', out3: 1})
    end
  end
end

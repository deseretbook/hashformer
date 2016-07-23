# Hashformer transformation generator tests
# Created July 2014 by Mike Bourgeous, DeseretBook.com
# Copyright (C)2016 Deseret Book
# See LICENSE and README.md for details.

require 'spec_helper'

require 'hashformer'

RSpec.describe Hashformer::Generate do
  describe '.const' do
    it 'returns the original integer when given an integer' do
      expect(Hashformer.transform({}, { a: HF::G.const(5) })).to eq({a: 5})
    end

    it 'returns the original array when given an array' do
      expect(Hashformer.transform({a: 1}, { a: HF::G.const([1, 2, :three]) })).to eq({a: [1, 2, :three]})
    end

    it 'returns a symbol when given a symbol' do
      expect(Hashformer.transform({q: nil}, { a: HF::G.const(:q) })).to eq({a: :q})
    end

    it 'can be used with .map' do
      expect(Hashformer.transform({}, { a: HF::G.map(HF::G.const(-1)) })).to eq({a: [-1]})
    end
  end

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

    it 'works with transformations as keys' do
      data = {
        a: 1,
        b: 2,
        c: 3
      }
      xform = {
        a: HF::G.map(:a, { a: HF::G.const(-1), b: :c }, :b)
      }
      expected = {
        a: [
          1,
          { a: -1, b: 3 },
          2
        ]
      }

      expect(Hashformer.transform(data, xform)).to eq(expected)
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

    it 'does not add more chained methods when Chain#inspect is called' do
      chain = HF[:test].one(1).two(2).three(3).four(4).five(5).__chain
      inspect = chain.inspect
      expect(inspect).to match(/one.*two.*three.*four.*five/)
      expect(chain.inspect).to eq(inspect)
      expect(chain.inspect).to eq(inspect)
    end

    describe '.__as' do
      it 'returns the value from the block' do
        xf = { out1: HF[:in1][:in1][0].__as{|v| "H#{v}shformer" } }
        expect(Hashformer.transform(data, xf)).to eq({ out1: 'Hashformer' })
      end

      it 'raises an error if no block is given' do
        expect{ HF[].__as() }.to raise_error(/No block given/)
      end
    end

    describe '.__end' do
      it 'prevents further method calls or __as blocks from being added' do
        xf = { out1: HF[:in1][:in1].count.__end.odd?.__as{nil}.__end.no.more.calls.added }
        expect(Hashformer.transform(data, xf)).to eq({ out1: 4 })
      end
    end

    context 'debugging methods' do
      it 'can enable and disable debugging' do
        begin
          HF::G::Chain.enable_debugging

          chain = HF[]

          expect($stdout).to receive(:puts).with(/Adding.*__as/)
          chain.__as{}

          expect($stdout).to receive(:puts).with(/Adding.*info/)
          chain.info

          expect($stdout).to receive(:puts).with(/Ending/)
          chain.__end

          expect($stdout).to receive(:puts).with(/Ignoring.*__as/)
          chain.__as{}

          expect($stdout).to receive(:puts).with(/Ignoring.*info/)
          chain.info


          HF::G::Chain.disable_debugging

          expect($stdout).not_to receive(:puts)
          HF[].add.__as{}.and.some.methods.then.__end.the.chain
        ensure
          HF::G::Chain.disable_debugging
        end
      end
    end

    context 'using normally reserved methods' do
      it 'calls a proc with .call' do
        calldata = {
          p: ->(*a){a.reduce(1, &:*)}
        }
        expect(Hashformer.transform(calldata, {o: HF[:p].call()})).to eq({o: 1})
        expect(Hashformer.transform(calldata, {o: HF[:p].call(5, 0)})).to eq({o: 0})
        expect(Hashformer.transform(calldata, {o: HF[:p].call(5, 4, 5)})).to eq({o: 100})
      end

      it 'sends messages to the correct target with .send' do
        senddata = {
          a: 'Hashformer'
        }
        sendxf = {
          b: HF[:a].clone.send(:reverse).send(:concat, ' transforms')
        }
        expect(Hashformer.transform(senddata, sendxf)).to eq({b: 'remrofhsaH transforms'})
      end

      it 'chains operators' do
        opxf = {
          a: !((HF[:a] + 3) == 8),
        }
        expect(Hashformer.transform({a: 5}, opxf)).to eq({a: false})
        expect(Hashformer.transform({a: 6}, opxf)).to eq({a: true})
      end

      it 'chains instance_exec' do
        class HFTestFoo
          def initialize(val)
            @y = val
          end
        end
        execxf = {
          x: -HF[:a].instance_exec{@y}
        }
        expect(Hashformer.transform({a: HFTestFoo.new(-1.5)}, execxf)).to eq({x: 1.5})
        expect(Hashformer.transform({a: HFTestFoo.new(2014)}, execxf)).to eq({x: -2014})
      end
    end
  end
end

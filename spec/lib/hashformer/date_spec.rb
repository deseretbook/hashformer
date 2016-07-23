# Hashformer date helper tests
# Created July 2016 by Mike Bourgeous, DeseretBook.com
# Copyright (C)2016 Deseret Book
# See LICENSE and README.md for details.

require 'rational'
require 'active_support/time'

describe Hashformer::Date do
  let(:data) {
    {
      one_time: Time.at(1),
      little_time: Time.at(0.25),
      no_time: nil,

      one_stamp: 1,
      little_stamp: 0.25,
      rational_stamp: Rational(3, 4),
      no_stamp: nil,
    }
  }

  describe '.to_i' do
    let(:xform) {
      {
        one: HF::Date.to_i(:one_time),
        zero: HF::Date.to_i(:little_time),
        none: HF::Date.to_i(:no_time),
      }
    }

    it 'converts dates to integer timestamps' do
      expect(HF.transform(data, xform)).to eq({ one: 1, zero: 0, none: nil })
    end

    it 'raises an error for invalid types' do
      expect{HF.transform({ one_time: 'Bogus' }, xform)}.to raise_error(/Invalid/)
    end
  end

  describe '.to_f' do
    let(:xform) {
      {
        one: HF::Date.to_f(:one_time),
        some: HF::Date.to_f(:little_time),
        none: HF::Date.to_f(:no_time),
      }
    }

    it 'converts dates to float timestamps' do
      expect(HF.transform(data, xform)).to eq({ one: 1.0, some: 0.25, none: nil })
    end

    it 'raises an error for invalid types' do
      expect{HF.transform({ one_time: 'Bogus' }, xform)}.to raise_error(/Invalid/)
    end
  end

  describe '.to_date' do
    let(:xform) {
      {
        one_utc: HF::Date.to_date(:one_stamp),
        little_utc: HF::Date.to_date(:little_stamp),
        rational_utc: HF::Date.to_date(:rational_stamp),

        one_local: HF::Date.to_date(:one_stamp, nil),
        little_local: HF::Date.to_date(:little_stamp, nil),
        rational_local: HF::Date.to_date(:rational_stamp, nil),

        one_zone: HF::Date.to_date(:one_stamp, 'MST'),
        little_zone: HF::Date.to_date(:little_stamp, 'MST'),
        rational_zone: HF::Date.to_date(:rational_stamp, 'MST'),
      }
    }

    let(:expected) {
      {
        one_utc: Time.at(1).utc.to_datetime,
        little_utc: Time.at(0.25).utc.to_datetime,
        rational_utc: Time.at(Rational(3, 4)).utc.to_datetime,

        one_local: Time.at(1).to_datetime,
        little_local: Time.at(0.25).to_datetime,
        rational_local: Time.at(Rational(3, 4)).to_datetime,

        one_zone: Time.at(1).in_time_zone('MST').to_datetime,
        little_zone: Time.at(0.25).in_time_zone('MST').to_datetime,
        rational_zone: Time.at(Rational(3, 4)).in_time_zone('MST').to_datetime,
      }
    }

    it 'converts timestamps to expected dates' do
      expect(HF.transform(data, xform)).to eq(expected)
    end
  end
end

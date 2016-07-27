# Hashformer date and time transformation generators.
# Created July 2016 by Mike Bourgeous, DeseretBook.com
# Copyright (C)2016 Deseret Book
# See LICENSE and README.md for details.

require 'date'
require 'time'

module Hashformer
  module Date
    # Generates a Proc to convert a Date, Time, or DateTime to an Integer UNIX
    # timestamp.  Passes nil through unmodified.  Useful for transforming to
    # serialization formats that don't support dates directly.
    #
    # Returns a method chain that can be further modified.
    #
    # Raises an error during transformation if the input value is not nil and
    # is a different class.
    #
    # Example:
    #   data = { time: Time.at(0.75), no_time: nil }
    #   xform = { ts: HF::Date.to_i(:time), ts2: HF::Date.to_i(:no_time) }
    #   HF.transform(data, xform)
    #   # => { ts: 0, ts2: nil }
    def self.to_i(key)
      HF[key].__as{|d|
        d = d.to_time if d.is_a?(::Date)
        raise "Invalid date/time class #{d.class}" unless d.nil? || d.is_a?(Time) || d.is_a?(DateTime)

        d && d.to_i
      }
    end

    # Generates a Proc to convert a Date, Time, or DateTime to a floating point
    # UNIX timestamp.  Passes nil through unmodified.  Useful for transforming
    # to serialization formats that don't support dates directly.
    #
    # Returns a method chain that can be further modified.
    #
    # Raises an error during transformation if the input value is not nil and
    # is a different class.
    #
    # Example:
    #   data = { time: Time.at(0.75), no_time: nil }
    #   xform = { ts: HF::Date.to_f(:time), ts2: HF::Date.to_f(:no_time) }
    #   HF.transform(data, xform)
    #   # => { ts: 0.75, ts2: nil }
    def self.to_f(key)
      HF[key].__as{|d|
        d = d.to_time if d.is_a?(::Date)
        raise "Invalid date/time class #{d.class}" unless d.nil? || d.is_a?(Time) || d.is_a?(DateTime)

        d && d.to_f
      }
    end

    # Generates a Proc to convert an Integer or Numeric UNIX timestamp to a
    # DateTime.  Passes nil through unmodified.  Useful for transforming from
    # serialization formats that don't support dates directly to database
    # interfaces that might expect DateTime rather than Time.
    #
    # If +tz_name+ is the default special value of :utc, then the resulting
    # DateTime will be in UTC time.  If +tz_name+ is nil, the default zone will
    # be used.  Otherwise, if +tz_name+ is given and the Time class responds to
    # #in_time_zone (requires ActiveSupport::TimeWithZone, which is not loaded
    # by Hashformer), then the date will be converted to the given named
    # timezone.
    #
    # Returns a method chain that can be further modified.
    #
    # Raises an error during transformation if the input value is not a type
    # supported by Time.at().
    #
    # Example:
    def self.to_date(key, tz_name = :utc)
      if tz_name == :utc
        HF[key].__as{|d|
          d && Time.at(d).utc.to_datetime
        }
      elsif tz_name
        raise 'ActiveSupport time helpers are required for tz_name' unless Time.instance_methods.include?(:in_time_zone)

        HF[key].__as{|d|
          d && Time.at(d).in_time_zone(tz_name).to_datetime
        }
      else
        HF[key].__as{|d|
          d && Time.at(d).to_datetime
        }
      end
    end
  end
end

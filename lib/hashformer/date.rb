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
    #   data = { time: Time.at(0.75) }
    #   xform = { ts: HF::G.date_to_int(:time) }
    #   HF.transform(data, xform)
    #   # => { ts: 0 }
    def self.date_to_int(key)
      HF[key].tap{|d|
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
    def self.date_to_float(key)
      HF[key].tap{|d|
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
    # If +tz_name+ is given and the Time class responds to #in_time_zone
    # (requires ActiveSupport::TimeWithZone, which is not loaded by
    # Hashformer), then the date will be converted to the given named timezone.
    #
    # Returns a method chain that can be further modified.
    #
    # Raises an error during transformation if the input value is not nil and
    # not Numeric.
    def self.n_to_date(key, tz_name = nil)
      if tz_name
        raise 'ActiveSupport time helpers are required for tz_name' unless Time.instance_methods.include?(:in_time_zone)

        HF[key].tap{|d|
          raise "Invalid timestamp class #{d.class}" unless d.nil? || d.is_a?(Numeric)
          d && Time.at(d).in_time_zone(tz_name).to_datetime
        }
      else
        HF[key].tap{|d|
          raise "Invalid timestamp class #{d.class}" unless d.nil? || d.is_a?(Numeric)
          d && Time.at(d).to_datetime
        }
      end
    end
  end
end

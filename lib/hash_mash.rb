# Hash Mash: A declarative data transformation DSL
# Created June 2014 by Mike Bourgeous, DeseretBook.com
# Copyright (C)2014 Deseret Book
# See LICENSE and README.md for details.

require "hash_mash/version"

require 'classy_hash'

# This module contains the HashMash methods for transforming Ruby Hash objects
# from one form to another.
module HashMash
  # Transforms +data+ according to the specification in +xform+.  The
  # transformation specification in +xform+ is a Hash specifying an input key
  # name (e.g. a String or Symbol) or transforming lambda for each output key
  # name.  If +validate+ is true, then ClassyHash::validate will be used to
  # validate the input and output data formats against the :@__in_schema and
  # :@__out_schema keys within +xform+, if specified.
  #
  # Nested transformations can be specified by calling HashMash::transform
  # again inside of a lambda.
  #
  # If a value in +xform+ is a Proc, the Proc will be called with the input
  # Hash, and the return value of the Proc used as the output value.
  #
  # If a key in +xform+ is a Proc, the Proc will be called with the exact
  # original input value from +xform+ (before calling a lambda, if applicable)
  # and the input Hash, and the return value of the Proc used as the name of
  # the output key.
  #
  # Example (see the README for more examples):
  #   HashMash.transform({old_name: 'Name'}, {new_name: :old_name}) # Returns {new_name: 'Name'}
  #   HashMash.transform({orig: 5}, {opposite: lambda{|i| -i[:orig]}}) # Returns {opposite: -5}
  def self.transform(data, xform, validate=true)
    raise 'Must transform a Hash' unless data.is_a?(Hash)
    raise 'Transformation must be a Hash' unless xform.is_a?(Hash)

    validate(data, xform[:__in_schema], 'input') if validate

    out = {}
    xform.each do |key, value|
      next if key == :__in_schema || key == :__out_schema

      key = key.call(value, data) if key.is_a?(Proc)
      value = value.is_a?(Proc) ? value.call(data) : data[value]
      out[key] = value
    end

    validate(out, xform[:__out_schema], 'output') if validate

    out
  end

  private
  def self.validate(data, schema, step)
    return unless schema.is_a?(Hash)

    begin
      ClassyHash.validate(data, schema)
    rescue => e
      raise "#{step} data failed validation: #{e}"
    end
  end
end

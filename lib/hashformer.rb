# Hashformer: A declarative data transformation DSL for Ruby
# Created June 2014 by Mike Bourgeous, DeseretBook.com
# Copyright (C)2014 Deseret Book
# See LICENSE and README.md for details.

require 'classy_hash'

require 'hashformer/version'
require 'hashformer/generate'


# This module contains the Hashformer methods for transforming Ruby Hash objects
# from one form to another.
#
# See README.md for examples.
module Hashformer
  # Transforms +data+ according to the specification in +xform+.  The
  # transformation specification in +xform+ is a Hash specifying an input key
  # name (e.g. a String or Symbol) or transforming lambda for each output key
  # name.  If +validate+ is true, then ClassyHash::validate will be used to
  # validate the input and output data formats against the :@__in_schema and
  # :@__out_schema keys within +xform+, if specified.
  #
  # Nested transformations can be specified by calling Hashformer::transform
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
  #   Hashformer.transform({old_name: 'Name'}, {new_name: :old_name}) # Returns {new_name: 'Name'}
  #   Hashformer.transform({orig: 5}, {opposite: lambda{|i| -i[:orig]}}) # Returns {opposite: -5}
  def self.transform(data, xform, validate=true)
    raise 'Must transform a Hash' unless data.is_a?(Hash)
    raise 'Transformation must be a Hash' unless xform.is_a?(Hash)

    validate(data, xform[:__in_schema], 'input') if validate

    out = {}
    xform.each do |key, value|
      next if key == :__in_schema || key == :__out_schema

      key = key.call(value, data) if key.respond_to?(:call)
      out[key] = self.get_value(data, value, xform)
    end

    validate(out, xform[:__out_schema], 'output') if validate

    out
  end

  # Returns a value for the given +key+, method chain, or callable on the given
  # +input_hash+.  If +xform+ is not nil, then Hashe keys will be processed
  # with Hashformer.transform.
  def self.get_value(input_hash, key, xform = nil)
    if Hashformer::Generate::Chain::Receiver === key
      # Had to special case chains to allow chaining .call
      key.__chain.call(input_hash)
    elsif key.respond_to?(:call)
      key.call(input_hash)
    elsif key.is_a?(Hash)
      transform(input_hash, key)
    else
      input_hash[key]
    end
  end

  private
  # Validates the given data against the given schema, at the given step.
  def self.validate(data, schema, step)
    return unless schema.is_a?(Hash)

    begin
      ClassyHash.validate(data, schema)
    rescue => e
      raise "#{step} data failed validation: #{e}"
    end
  end
end

if !Kernel.const_defined?(:HF)
  HF = Hashformer
end

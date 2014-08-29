# Hashformer transformation generators
# Created July 2014 by Mike Bourgeous, DeseretBook.com
# Copyright (C)2014 Deseret Book
# See LICENSE and README.md for details.

require 'classy_hash'

module Hashformer
  # This module contains simple methods for generating complex transformations
  # for Hashformer.
  module Generate
    # Internal representation of a mapping transformation.  Do not instantiate
    # directly; call Hashformer::Generate.map (or HF::G.map) instead.
    class Map
      def initialize(*keys_or_callables, &block)
        @keys = keys_or_callables
        @block = block
      end

      # Called to process the map on the given +input_hash+
      def call(input_hash)
        values = @keys.map{|k| Hashformer.get_value(input_hash, k)}
        values = @block.call(*values) if @block
        values
      end

      # TODO: Make maps chainable?  Or at least add a #reduce method.
    end

    # Internal representation of a path to a nested key/value.  Do not
    # instantiate directly; call Hashformer::Generate.path (or HF::G.path)
    # instead.
    class Path
      def initialize
        @pathlist = []
      end

      # Called to dereference the path on the given +input_hash+.
      def call(input_hash)
        begin
          value = input_hash
          @pathlist.each do |path_item|
            value = value && value[path_item]
          end
          value
        rescue => e
          raise "Error dereferencing path #{self}: #{e}"
        end
      end

      # Adds a path item to the end of the saved path.
      def [](path_item)
        @pathlist << path_item
        self
      end

      def to_s
        @pathlist.map{|p| "[#{p.inspect}]"}.join
      end
    end

    # Internal representation of a method call and array lookup chainer.  Do
    # not use this directly; instead use HF::G.chain().
    class Chain
      # Receiver for chaining calls that has no methods of its own except
      # initialize.  This allows methods like :call to be chained.
      #
      # IMPORTANT: No methods other than .__chain can be called on this object,
      # because they will be chained!  Instead, use === to detect the object's
      # type, for example.
      class Receiver < BasicObject
        # An oddly named accessor is used instead of #initialize to avoid
        # conflicts with any methods that might be chained.
        attr_accessor :__chain

        # Adds a method call or array dereference to the list of calls to apply.
        def method_missing(name, *args, &block)
          @__chain << {name: name, args: args, block: block}
          self
        end

        undef !=
        undef ==
        undef !
        undef instance_exec
        undef instance_eval
        undef equal?
        undef singleton_method_added
        undef singleton_method_removed
        undef singleton_method_undefined
      end

      # Returns the call chaining receiver.
      attr_reader :receiver

      def initialize
        @calls = []
        @receiver = Receiver.new
        @receiver.__chain = self
      end

      # Applies the methods stored by #method_missing
      def call(input_hash)
        value = input_hash
        @calls.each do |c|
          value = value.send(c[:name], *c[:args], &c[:block])
        end
        value
      end

      # Adds the given call info (used by Receiver).
      def <<(info)
        @calls << info
        self
      end

      # Returns a String with the class name and a list of chained methods.
      def to_s
        "#{self.class.name}: #{@calls.map{|c| c[:name]}}"
      end
      alias inspect to_s
    end

    # TODO: Add a constant generator (that can be chained?)

    # Generates a transformation that passes one or more values from the input
    # Hash (denoted by key names or paths (see Hashformer::Generate.path) to
    # the block.  If the block is not given, then the values are placed in an
    # array in the order in which their keys were given as parameters.
    #
    # Examples:
    #   HF::G.map(:first, :last) do |f, l| "#{f} #{l}".strip end
    #   HF::G.map(:a1, :a2) # Turns {a1: 1, a2: 2} into [1, 2]
    #   HF::G.map(HF::G.path[:address][:line1], HF::G.path[:address][:line2])
    def self.map(*keys_or_paths, &block)
      Map.new(*keys_or_paths, &block)
    end

    # Generates a path reference (via Path#[]) that grabs a nested value for
    # use directly or in other transformations.  If no path is specified, the
    # transformation will use the input hash.
    #
    # When the path is dereferenced, if any of the parent elements referred to
    # by the path are nil, then nil will be returned.  If any path elements do
    # not respond to [], or otherwise raise an exception, then an exception
    # will be raised by the transformation.
    #
    # The major difference between .path and .chain is that .path will return
    # nil if a nonexistent key is referenced (even multiple times), while
    # .chain will raise an exception.
    #
    # Examples:
    #   HF::G.path[:user][:address][:line1]
    #   HF::G.path[:lines][5]
    def self.path
      Path.new
    end

    # Generates a method call chain to apply to the input hash given to a
    # transformation.  This allows path references (as with HF::G.path) and
    # method calls to be stored and applied later.
    #
    # Example:
    #   data = { in1: { in2: [1, 2, 3, [4, 5, 6, 7]] } }
    #   xform = { out1: HF::G.chain[:in1][:in2][3].reduce(&:+) }
    #   Hashformer.transform(data, xform) # Returns { out1: 22 }
    def self.chain
      Chain.new.receiver
    end
  end

  # Shortcut to Hashformer::Generate
  G = Generate

  # Convenience method for calling HF::G.chain() to generate a path reference
  # and/or method call chain.  If the initial +path_item+ is not given, then
  # the method chain will start with the input hash.  Chaining methods that
  # have side effects or modify the underlying data is not recommended.
  #
  # Example:
  #   data = { in1: { in2: ['a', 'b', 'c', 'd'] } }
  #   xform = { out1: HF[:in1][:in2][3], out2: HF[].count }
  #   Hashformer.transform(data, xform) # Returns { out1: 'd', out2: 1 }
  def self.[](path_item = :__hashformer_not_given)
    path_item == :__hashformer_not_given ? HF::G.chain : HF::G.chain[path_item]
  end
end

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
      # Base module that defines methods included by BasicReceiver and
      # DebuggableReceiver.
      module ReceiverMethods
        # An oddly named accessor is used instead of #initialize to avoid
        # conflicts with any methods that might be chained.
        attr_accessor :__chain

        # Adds a method call or array dereference to the list of calls to
        # apply.  Does nothing if #__end has been called.  Returns self for
        # more chaining.
        def method_missing(name, *args, &block)
          @__ended ||= false
          @__chain << {name: name, args: args, block: block} unless @__ended
          self
        end

        # Adds a call to the given +block+ to the chain like Object#tap, but
        # returns the result of the block instead of the original object.  Any
        # arguments given will be passed to the +block+ after the current
        # value.  Does nothing if #__end has been called.  Returns self for
        # more chaining.
        #
        # This is similar in spirit (but not implementation) to
        # http://stackoverflow.com/a/12849214
        def __as(*args, &block)
          ::Kernel.raise 'No block given to #__as' unless ::Kernel.block_given?
          @__ended ||= false
          @__chain << {args: args, block: block} unless @__ended
          self
        end

        # Disables further chaining.  Any future method calls will just return
        # the existing chain without modifying it.
        def __end
          @__ended = true
          self
        end
      end

      # Receiver for chaining calls that has no methods of its own except
      # initialize.  This allows methods like :call to be chained.
      #
      # IMPORTANT: No methods other than #__chain, #__as, or #__end should be
      # called on this object, because they will be chained!  Instead, use ===
      # to detect the object's type, for example.
      class BasicReceiver < BasicObject
        include ReceiverMethods

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

      # Debuggable chain receiver that inherits from Object.  This will break a
      # lot of chains (e.g. any chain using #to_s or #inspect), but will allow
      # some debugging tools to operate without crashing.  See
      # Hashformer::Generate::Chain.enable_debugging.
      class DebuggableReceiver
        include ReceiverMethods

        # Overrides ReceiverMethods#method_missing to print out methods as they
        # are added to the chain.
        def method_missing(name, *args, &block)
          __dbg_msg(name, args, block)
          super
        end

        # Overrides ReceiverMethods#__as to print out blocks as they are added
        # to the chain.
        def __as(*args, &block)
          __dbg_msg('__as', args, block)
          super
        end

        # Overrides ReceiverMethods#__end to print a message when a chain is
        # ended.
        def __end
          $stdout.puts "Ending chain #{__id__}"
          super
        end

        private

        # Prints a debugging message for the addition of the given method
        # +name+, +args+, and +block+.  Prints "Adding..." for active chains,
        # "Ignoring..." for ended chains.
        def __dbg_msg(name, args, block)
          $stdout.puts "#{@__ended ? 'Ignoring' : 'Adding'} " \
            "#{name.inspect}(#{args.map(&:inspect).join(', ')}){#{block}} " \
            "to chain #{__id__}"
        end
      end

      class << self
        # The chaining receiver class that will be used by newly created chains
        # (must include ReceiverMethods).
        def receiver_class
          @receiver_class ||= BasicReceiver
        end

        # Switches Receiver to an Object (DebuggableReceiver) for debugging.
        # debugging tools to introspect Receiver without crashing.
        def enable_debugging
          @receiver_class = DebuggableReceiver
        end

        # Switches Receiver back to a BasicObject (BasicReceiver).
        def disable_debugging
          @receiver_class = BasicReceiver
        end
      end


      # Returns the call chaining receiver for this chain.
      attr_reader :receiver

      # Initializes an empty chain.
      def initialize
        @calls = []
        @receiver = self.class.receiver_class.new
        @receiver.__chain = self
      end

      # Applies the methods stored by #method_missing
      def call(input_hash)
        value = input_hash
        @calls.each do |c|
          if c[:name]
            value = value.send(c[:name], *c[:args], &c[:block])
          else
            # Support #__as
            value = c[:block].call(value, *c[:args])
          end
        end
        value
      end

      # Adds the given call info (used by ReceiverMethods).
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

    # Internal representation of a constant output value.  Do not instantiate
    # directly; call Hashformer::Generate.const (or HF::G.const) instead.
    class Constant
      attr_reader :value

      def initialize(value)
        @value = value
      end
    end


    # Generates a transformation that always returns a constant value.
    #
    # Examples:
    #   HF::G.const(5)
    def self.const(value)
      Constant.new(value)
    end

    # Generates a transformation that passes one or more values from the input
    # Hash (denoted by key names or paths (see Hashformer::Generate.path) to
    # the block.  If the block is not given, then the values are placed in an
    # array in the order in which their keys were given as parameters.
    #
    # You can also pass a Hashformer transformation Hash as one or more keys.
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
    # See Hashformer::Generate::Chain.enable_debugging if you run into issues.
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

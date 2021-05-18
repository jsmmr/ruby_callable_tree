# frozen_string_literal: true

module CallableTree
  module Node
    module External
      include Node

      def self.proxify(callable)
        Proxy.new(callable)
      end

      def self.proxified?(node)
        node.is_a?(Proxy)
      end

      def self.unproxify(node)
        node.callable
      end

      def verbosify
        extend Verbose
        self
      end

      def identity
        if External.proxified?(self)
          External.unproxify(self)
        else
          self
        end
          .class
      end

      class Proxy
        extend ::Forwardable
        include External

        def_delegators :@callable, :call
        attr_reader :callable

        def initialize(callable)
          @callable = callable
        end
      end

      private_constant :Proxy
    end
  end
end

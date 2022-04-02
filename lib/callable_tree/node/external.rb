# frozen_string_literal: true

module CallableTree
  module Node
    module External
      include Node

      def self.included(mod)
        if mod.include?(Internal)
          raise ::CallableTree::Error,
                "#{mod} cannot include #{self} together with #{Internal}"
        end
      end

      def self.proxify(callable)
        Proxy.new(callable)
      end

      def proxified?
        false
      end

      def verbosified?
        false
      end

      def verbosify
        clone.tap do |node|
          node.extend Verbose
        end
      end

      def verbosify!
        extend Verbose
        self
      end

      def identity
        if proxified?
          unproxify
        else
          self
        end
          .class
      end

      def outline
        { identity => nil }
      end

      private

      def initialize_copy(_node)
        super
        self.parent = nil
      end

      class Proxy
        extend ::Forwardable
        include External

        def_delegators :@callable, :call

        def initialize(callable)
          @callable = callable
        end

        def proxified?
          true
        end

        def unproxify
          @callable
        end
      end

      private_constant :Proxy
    end
  end
end

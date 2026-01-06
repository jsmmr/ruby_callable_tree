# frozen_string_literal: true

module CallableTree
  module Node
    module Internal
      # Pod: A node that can be instantiated directly with proc-based behavior.
      # Provides an alternative to Builder style for inline node creation.
      #
      # Usage patterns:
      #   Constructor style: Pod.new(caller: ->(input, **) { input * 2 })
      #   Factory style: Internal.create(caller: ->(input, **) { input * 2 })
      #   Block style: Internal.create { |node| node.caller { |input, **| input * 2 } }
      class Pod
        include Internal

        def initialize(matcher: nil, caller: nil, terminator: nil, identifier: nil)
          @_matcher = matcher
          @_caller = caller
          @_terminator = terminator
          @_identifier = identifier

          yield self if block_given?
        end

        # DSL setters for block syntax
        def matcher(proc = nil, &block)
          @_matcher = proc || block
          self
        end

        def caller(proc = nil, &block)
          @_caller = proc || block
          self
        end

        def terminator(proc = nil, &block)
          @_terminator = proc || block
          self
        end

        def identifier(proc = nil, &block)
          @_identifier = proc || block
          self
        end

        def match?(*inputs, **options)
          return super unless @_matcher

          @_matcher.call(*inputs, **options, _node_: self) do |*a, **o|
            super(*a, **o)
          end
        end

        def call(*inputs, **options)
          return super unless @_caller

          @_caller.call(*inputs, **options, _node_: self) do |*a, **o|
            super(*a, **o)
          end
        end

        def terminate?(output, *inputs, **options)
          return super unless @_terminator

          @_terminator.call(output, *inputs, **options, _node_: self) do |o, *a, **opts|
            super(o, *a, **opts)
          end
        end

        def identity
          return super unless @_identifier

          @_identifier.call(_node_: self) { super }
        end
      end

      # HookablePod: Pod with Hooks support (before/around/after callbacks).
      class HookablePod < Pod
        prepend Hooks::Matcher
        prepend Hooks::Caller
        prepend Hooks::Terminator
      end

      # Factory method
      def self.create(matcher: nil, caller: nil, terminator: nil, identifier: nil, hookable: false, &block)
        klass = hookable ? HookablePod : Pod
        klass.new(matcher: matcher, caller: caller, terminator: terminator, identifier: identifier, &block)
      end
    end
  end
end

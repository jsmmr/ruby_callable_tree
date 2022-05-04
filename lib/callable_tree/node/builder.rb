# frozen_string_literal: true

module CallableTree
  module Node
    module Builder
      def matcher(&block)
        @matcher = block
        self
      end

      def caller(&block)
        @caller = block
        self
      end

      def terminater(&block)
        warn 'Use CallableTree::Node::Internal::Builder#terminator instead.'
        @terminator = block
        self
      end

      def terminator(&block)
        @terminator = block
        self
      end

      def identifier(&block)
        @identifier = block
        self
      end

      def hookable(hookable = true)
        @hookable = hookable
        self
      end

      def build(node_type:)
        matcher = @matcher
        caller = @caller
        terminator = @terminator
        identifier = @identifier
        hookable = @hookable

        validate(
          matcher: matcher,
          caller: caller,
          terminator: terminator
        )

        ::Class
          .new do
            include node_type
            if hookable
              prepend Hooks::Matcher
              prepend Hooks::Caller
            end

            if matcher
              define_method(:match?) do |*inputs, **options|
                matcher.call(*inputs, **options, _node_: self) do |*inputs, **options|
                  super(*inputs, **options)
                end
              end
            end

            if caller
              define_method(:call) do |*inputs, **options|
                caller.call(*inputs, **options, _node_: self) do |*inputs, **options|
                  super(*inputs, **options)
                end
              end
            end

            if terminator
              define_method(:terminate?) do |output, *inputs, **options|
                terminator.call(output, *inputs, **options, _node_: self) do |output, *inputs, **options|
                  super(output, *inputs, **options)
                end
              end
            end

            if identifier
              define_method(:identity) do
                identifier.call(_node_: self) { super() }
              end
            end
          end
      end

      private

      def validate(matcher:, caller:, terminator:)
        raise ::CallableTree::Error, 'Not implemented'
      end
    end
  end
end

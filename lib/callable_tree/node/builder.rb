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
        @terminater = block
        self
      end

      def hookable(hookable = true)
        @hookable = hookable
        self
      end

      def build(node_type:)
        matcher = @matcher
        caller = @caller
        terminater = @terminater
        hookable = @hookable

        validate(
          matcher: matcher,
          caller: caller,
          terminater: terminater
        )

        ::Class
          .new do
            include node_type
            prepend Hooks::Call if hookable

            if matcher
              define_method(:match?) do |*inputs, **options|
                matcher.call(*inputs, **options) do |*inputs, **options|
                  super(*inputs, **options)
                end
              end
            end

            if caller
              define_method(:call) do |*inputs, **options|
                caller.call(*inputs, **options) do |*inputs, **options|
                  super(*inputs, **options)
                end
              end
            end

            if terminater
              define_method(:terminate?) do |output, *inputs, **options|
                terminater.call(output, *inputs, **options) do |output, *inputs, **options|
                  super(output, *inputs, **options)
                end
              end
            end
          end
      end

      private

      def validate(matcher:, caller:, terminater:)
        raise ::CallableTree::Error, 'Not implemented'
      end
    end
  end
end

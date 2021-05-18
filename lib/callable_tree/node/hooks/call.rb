# frozen_string_literal: true

module CallableTree
  module Node
    module Hooks
      module Call
        def self.included(_subclass)
          raise ::CallableTree::Error, "#{self} must be prepended"
        end

        def before_call(&block)
          before_callbacks << block
          self
        end

        def around_call(&block)
          around_callbacks << block
          self
        end

        def after_call(&block)
          after_callbacks << block
          self
        end

        def call(input = nil, **options)
          input = before_callbacks.reduce(input) do |input, callable|
            callable.call(input, self, **options)
          end

          output = super(input, **options)

          output = around_callbacks.reduce(output) do |output, callable|
            callable.call(input, self, **options) { output }
          end

          after_callbacks.reduce(output) do |output, callable|
            callable.call(output, self, **options)
          end
        end

        def before_callbacks
          @before_callbacks ||= []
        end

        def around_callbacks
          @around_callbacks ||= []
        end

        def after_callbacks
          @after_callbacks ||= []
        end

        private

        attr_writer :before_callbacks, :around_callbacks, :after_callbacks

        def initialize_copy(_node)
          super
          self.before_callbacks = before_callbacks.map(&:itself)
          self.around_callbacks = around_callbacks.map(&:itself)
          self.after_callbacks = after_callbacks.map(&:itself)
        end
      end
    end
  end
end

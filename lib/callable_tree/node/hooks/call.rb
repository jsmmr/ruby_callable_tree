# frozen_string_literal: true

module CallableTree
  module Node
    module Hooks
      module Call
        def self.included(_subclass)
          raise ::CallableTree::Error, "#{self} must be prepended"
        end

        def before_call(&block)
          clone.before_call!(&block)
        end

        def before_call!(&block)
          before_caller_callbacks << block
          self
        end

        def around_call(&block)
          clone.around_call!(&block)
        end

        def around_call!(&block)
          around_caller_callbacks << block
          self
        end

        def after_call(&block)
          clone.after_call!(&block)
        end

        def after_call!(&block)
          after_caller_callbacks << block
          self
        end

        alias before_caller before_call
        alias before_caller! before_call!
        alias around_caller around_call
        alias around_caller! around_call!
        alias after_caller after_call
        alias after_caller! after_call!

        def call(*inputs, **options)
          input_head, *input_tail = inputs

          input_head = before_caller_callbacks.reduce(input_head) do |input_head, callable|
            callable.call(input_head, *input_tail, **options, _node_: self)
          end

          output =
            if around_caller_callbacks.empty?
              super(input_head, *input_tail, **options)
            else
              around_caller_callbacks_head, *around_caller_callbacks_tail = around_caller_callbacks
              caller = proc { super(input_head, *input_tail, **options) }

              output =
                around_caller_callbacks_head
                .call(
                  input_head,
                  *input_tail,
                  **options,
                  _node_: self
                ) { caller.call }

              around_caller_callbacks_tail.reduce(output) do |output, callable|
                callable.call(
                  input_head,
                  *input_tail,
                  **options,
                  _node_: self
                ) { output }
              end
            end

          after_caller_callbacks.reduce(output) do |output, callable|
            callable.call(output, **options, _node_: self)
          end
        end

        def before_caller_callbacks
          @before_caller_callbacks ||= []
        end

        def around_caller_callbacks
          @around_caller_callbacks ||= []
        end

        def after_caller_callbacks
          @after_caller_callbacks ||= []
        end

        private

        attr_writer :before_caller_callbacks, :around_caller_callbacks, :after_caller_callbacks

        def initialize_copy(_node)
          super
          self.before_caller_callbacks = before_caller_callbacks.map(&:itself)
          self.around_caller_callbacks = around_caller_callbacks.map(&:itself)
          self.after_caller_callbacks = after_caller_callbacks.map(&:itself)
        end
      end
    end
  end
end

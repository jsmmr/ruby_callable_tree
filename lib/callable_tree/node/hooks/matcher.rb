# frozen_string_literal: true

module CallableTree
  module Node
    module Hooks
      module Matcher
        def self.included(_subclass)
          raise ::CallableTree::Error, "#{self} must be prepended"
        end

        def before_matcher(&block)
          clone.before_matcher!(&block)
        end

        def before_matcher!(&block)
          before_matcher_callbacks << block
          self
        end

        def around_matcher(&block)
          clone.around_matcher!(&block)
        end

        def around_matcher!(&block)
          around_matcher_callbacks << block
          self
        end

        def after_matcher(&block)
          clone.after_matcher!(&block)
        end

        def after_matcher!(&block)
          after_matcher_callbacks << block
          self
        end

        def match?(*inputs, **options)
          input_head, *input_tail = inputs

          input_head = before_matcher_callbacks.reduce(input_head) do |input_head, callable|
            callable.call(input_head, *input_tail, **options, _node_: self)
          end

          matched =
            if around_matcher_callbacks.empty?
              super(input_head, *input_tail, **options)
            else
              around_matcher_callbacks_head, *around_matcher_callbacks_tail = around_matcher_callbacks
              matcher = proc { super(input_head, *input_tail, **options) }

              matched =
                around_matcher_callbacks_head
                .call(
                  input_head,
                  *input_tail,
                  **options,
                  _node_: self
                ) { matcher.call }

              around_matcher_callbacks_tail.reduce(matched) do |matched, callable|
                callable.call(
                  input_head,
                  *input_tail,
                  **options,
                  _node_: self
                ) { matched }
              end
            end

          after_matcher_callbacks.reduce(matched) do |matched, callable|
            callable.call(matched, **options, _node_: self)
          end
        end

        def before_matcher_callbacks
          @before_matcher_callbacks ||= []
        end

        def around_matcher_callbacks
          @around_matcher_callbacks ||= []
        end

        def after_matcher_callbacks
          @after_matcher_callbacks ||= []
        end

        private

        attr_writer :before_matcher_callbacks, :around_matcher_callbacks, :after_matcher_callbacks

        def initialize_copy(_node)
          super
          self.before_matcher_callbacks = before_matcher_callbacks.map(&:itself)
          self.around_matcher_callbacks = around_matcher_callbacks.map(&:itself)
          self.after_matcher_callbacks = after_matcher_callbacks.map(&:itself)
        end
      end
    end
  end
end

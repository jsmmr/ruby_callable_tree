# frozen_string_literal: true

module CallableTree
  module Node
    module Hooks
      module Terminator
        def self.included(_subclass)
          raise ::CallableTree::Error, "#{self} must be prepended"
        end

        def before_terminator(&block)
          clone.before_terminator!(&block)
        end

        def before_terminator!(&block)
          before_terminator_callbacks << block
          self
        end

        def around_terminator(&block)
          clone.around_terminator!(&block)
        end

        def around_terminator!(&block)
          around_terminator_callbacks << block
          self
        end

        def after_terminator(&block)
          clone.after_terminator!(&block)
        end

        def after_terminator!(&block)
          after_terminator_callbacks << block
          self
        end

        def terminate?(output, *inputs, **options)
          output = before_terminator_callbacks.reduce(output) do |output, callable|
            callable.call(output, *inputs, **options, _node_: self)
          end

          terminated =
            if around_terminator_callbacks.empty?
              super
            else
              around_terminator_callbacks_head, *around_terminator_callbacks_tail = around_terminator_callbacks
              terminator = proc { super(output, *inputs, **options) }

              terminated =
                around_terminator_callbacks_head
                .call(
                  output,
                  *inputs,
                  **options,
                  _node_: self
                ) { terminator.call }

              around_terminator_callbacks_tail.reduce(terminated) do |terminated, callable|
                callable.call(
                  output,
                  *inputs,
                  **options,
                  _node_: self
                ) { terminated }
              end
            end

          after_terminator_callbacks.reduce(terminated) do |terminated, callable|
            callable.call(terminated, **options, _node_: self)
          end
        end

        def before_terminator_callbacks
          @before_terminator_callbacks ||= []
        end

        def around_terminator_callbacks
          @around_terminator_callbacks ||= []
        end

        def after_terminator_callbacks
          @after_terminator_callbacks ||= []
        end

        private

        attr_writer :before_terminator_callbacks, :around_terminator_callbacks, :after_terminator_callbacks

        def initialize_copy(_node)
          super
          self.before_terminator_callbacks = before_terminator_callbacks.map(&:itself)
          self.around_terminator_callbacks = around_terminator_callbacks.map(&:itself)
          self.after_terminator_callbacks = after_terminator_callbacks.map(&:itself)
        end
      end
    end
  end
end

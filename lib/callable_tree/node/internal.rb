# frozen_string_literal: true

module CallableTree
  module Node
    module Internal
      include Node

      def children
        @children ||= []
      end

      def append(*callables)
        callables
          .map { |callable| nodeify(callable) }
          .tap { |nodes| children.append(*nodes) }

        self
      end

      def match?(_input = nil, **_options)
        !children.empty?
      end

      def call(input = nil, **options)
        strategy.call(children, input: input, options: options)
      end

      def seek
        if strategy.is_a?(Seek)
          self
        else
          clone.tap do |node|
            node.send(:strategy=, Seek.new)
          end
        end
      end

      def broadcast
        if strategy.is_a?(Broadcast)
          self
        else
          clone.tap do |node|
            node.send(:strategy=, Broadcast.new)
          end
        end
      end

      def compose
        if strategy.is_a?(Compose)
          self
        else
          clone.tap do |node|
            node.send(:strategy=, Compose.new)
          end
        end
      end

      private

      attr_writer :children, :strategy

      def nodeify(callable)
        if callable.is_a?(Node)
          callable.clone
        else
          External.proxify(callable)
        end
        .tap { |node| node.send(:parent=, self) }
      end

      def strategy
        @strategy ||= Seek.new
      end

      def initialize_copy(_node)
        super
        self.children = children.map do |node|
          node.clone.tap { |new_node| new_node.send(:parent=, self) }
        end
      end
    end
  end
end

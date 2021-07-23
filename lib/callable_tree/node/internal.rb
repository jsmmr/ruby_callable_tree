# frozen_string_literal: true

module CallableTree
  module Node
    module Internal
      include Node

      def children
        @children ||= []
      end

      def append(*callables)
        clone.tap do |node|
          node.append!(*callables)
        end
      end

      def append!(*callables)
        callables
          .map { |callable| nodeify(callable) }
          .tap { |nodes| children.push(*nodes) } # Use Array#push for Ruby 2.4

        self
      end

      def match?(_input = nil, **_options)
        !children.empty?
      end

      def call(input = nil, **options)
        strategy.call(children, input: input, options: options)
      end

      def seek
        if strategy.is_a?(Strategy::Seek)
          self
        else
          clone.tap do |node|
            node.send(:strategy=, Strategy::Seek.new)
          end
        end
      end

      def seek!
        self.strategy = Strategy::Seek.new unless strategy.is_a?(Strategy::Seek)
        self
      end

      def broadcast
        if strategy.is_a?(Strategy::Broadcast)
          self
        else
          clone.tap do |node|
            node.send(:strategy=, Strategy::Broadcast.new)
          end
        end
      end

      def broadcast!
        self.strategy = Strategy::Broadcast.new unless strategy.is_a?(Strategy::Broadcast)
        self
      end

      def compose
        if strategy.is_a?(Strategy::Compose)
          self
        else
          clone.tap do |node|
            node.send(:strategy=, Strategy::Compose.new)
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
        @strategy ||= Strategy::Seek.new
      end

      def initialize_copy(_node)
        super
        self.parent = nil
        self.children = children.map do |node|
          node.clone.tap { |new_node| new_node.send(:parent=, self) }
        end
      end
    end
  end
end

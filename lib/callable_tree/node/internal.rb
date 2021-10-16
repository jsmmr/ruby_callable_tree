# frozen_string_literal: true

module CallableTree
  module Node
    module Internal
      include Node

      def children
        # TODO: Change to return a new array instance.
        child_nodes
      end

      def append(*callables)
        clone.tap do |node|
          node.append!(*callables)
        end
      end

      def append!(*callables)
        callables
          .map { |callable| nodeify(callable) }
          .tap { |nodes| child_nodes.push(*nodes) } # Use Array#push for Ruby 2.4

        self
      end

      def match?(_input = nil, **_options)
        !child_nodes.empty?
      end

      def call(input = nil, **options)
        strategy.call(child_nodes, input: input, options: options)
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

      def compose!
        self.strategy = Strategy::Compose.new unless strategy.is_a?(Strategy::Compose)
        self
      end

      private

      attr_writer :child_nodes, :strategy

      def child_nodes
        @child_nodes ||= []
      end

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
        self.child_nodes = child_nodes.map do |node|
          node.clone.tap { |new_node| new_node.send(:parent=, self) }
        end
      end
    end
  end
end

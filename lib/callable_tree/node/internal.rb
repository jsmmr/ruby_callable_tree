# frozen_string_literal: true

module CallableTree
  module Node
    module Internal
      extend ::Forwardable
      include Node

      def_delegators :child_nodes, :[], :at

      def children
        [*child_nodes]
      end

      def children!
        child_nodes
      end

      def append(*callables)
        clone.append!(*callables)
      end

      def append!(*callables)
        callables
          .map { |callable| nodeify(callable) }
          .tap { |nodes| child_nodes.push(*nodes) }

        self
      end

      def find(recursive: false, &block)
        node = child_nodes.find(&block)
        return node if node

        if recursive
          child_nodes
            .lazy
            .select { |node| node.is_a?(Internal) }
            .map { |node| node.find(recursive: true, &block) }
            .reject(&:nil?)
            .first
        end
      end

      def reject(recursive: false, &block)
        clone.reject!(recursive: recursive, &block)
      end

      def reject!(recursive: false, &block)
        child_nodes.reject!(&block)

        if recursive
          child_nodes.each do |node|
            node.reject!(recursive: true, &block) if node.is_a?(Internal)
          end
        end

        self
      end

      def shake(&block)
        clone.shake!(&block)
      end

      def shake!(&block)
        reject!(&block) if block_given?

        reject! do |node|
          node.is_a?(Internal) && node.shake!(&block).child_nodes.empty?
        end
      end

      def match?(*, **)
        !child_nodes.empty?
      end

      def call(*inputs, **options)
        strategy.call(child_nodes, *inputs, **options)
      end

      def seek?
        strategy.is_a?(Strategy::Seek)
      end

      def seek
        if seek?
          self
        else
          clone.tap do |node|
            node.strategy = Strategy::Seek.new
          end
        end
      end

      def seek!
        tap do |node|
          node.strategy = Strategy::Seek.new unless seek?
        end
      end

      def broadcast?
        strategy.is_a?(Strategy::Broadcast)
      end

      def broadcast
        if broadcast?
          self
        else
          clone.tap do |node|
            node.strategy = Strategy::Broadcast.new
          end
        end
      end

      def broadcast!
        tap do |node|
          node.strategy = Strategy::Broadcast.new unless broadcast?
        end
      end

      def compose?
        strategy.is_a?(Strategy::Compose)
      end

      def compose
        if compose?
          self
        else
          clone.tap do |node|
            node.strategy = Strategy::Compose.new
          end
        end
      end

      def compose!
        tap do |node|
          node.strategy = Strategy::Compose.new unless compose?
        end
      end

      def outline(&block)
        key = block ? block.call(self) : identity
        value = child_nodes.reduce({}) { |memo, node| memo.merge!(node.outline(&block)) }
        { key => value }
      end

      protected

      attr_writer :strategy

      def child_nodes
        @child_nodes ||= []
      end

      private

      attr_writer :child_nodes

      def nodeify(callable)
        if callable.is_a?(Node)
          callable.clone
        else
          External.proxify(callable)
        end
          .tap { |node| node.parent = self }
      end

      def strategy
        @strategy ||= Strategy::Seek.new
      end

      def initialize_copy(_node)
        super
        self.parent = nil
        self.child_nodes = child_nodes.map do |node|
          node.clone.tap { |new_node| new_node.parent = self }
        end
      end
    end
  end
end

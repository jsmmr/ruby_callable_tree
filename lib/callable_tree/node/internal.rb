# frozen_string_literal: true

module CallableTree
  module Node
    module Internal
      extend ::Forwardable
      include Node

      def self.included(mod)
        if mod.include?(External)
          raise ::CallableTree::Error,
                "#{mod} cannot include #{self} together with #{External}"
        end
      end

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
            .select(&:internal?)
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
            node.reject!(recursive: true, &block) if node.internal?
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
          node.internal? && node.shake!(&block).child_nodes.empty?
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

      def seek(matchable: true, terminable: true)
        if strategy == Strategy::Seek.new(matchable: matchable, terminable: terminable)
          self
        else
          clone.seek!(matchable: matchable, terminable: terminable)
        end
      end

      def seek!(matchable: true, terminable: true)
        self.strategy = Strategy::Seek.new(matchable: matchable, terminable: terminable)

        self
      end

      alias seekable? seek?
      alias seekable seek
      alias seekable! seek!

      def broadcast?
        strategy.is_a?(Strategy::Broadcast)
      end

      def broadcast(matchable: true, terminable: false)
        if strategy == Strategy::Broadcast.new(matchable: matchable, terminable: terminable)
          self
        else
          clone.broadcast!(matchable: matchable, terminable: terminable)
        end
      end

      def broadcast!(matchable: true, terminable: false)
        self.strategy = Strategy::Broadcast.new(matchable: matchable, terminable: terminable)

        self
      end

      alias broadcastable? broadcast?
      alias broadcastable broadcast
      alias broadcastable! broadcast!

      def compose?
        strategy.is_a?(Strategy::Compose)
      end

      def compose(matchable: true, terminable: false)
        if strategy == Strategy::Compose.new(matchable: matchable, terminable: terminable)
          self
        else
          clone.compose!(matchable: matchable, terminable: terminable)
        end
      end

      def compose!(matchable: true, terminable: false)
        self.strategy = Strategy::Compose.new(matchable: matchable, terminable: terminable)

        self
      end

      alias composable? compose?
      alias composable compose
      alias composable! compose!

      def outline(&block)
        key = block ? block.call(self) : identity
        value = child_nodes.reduce({}) { |memo, node| memo.merge!(node.outline(&block)) }
        { key => value }
      end

      def internal?
        true
      end

      def external?
        false
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

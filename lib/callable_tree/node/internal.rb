# frozen_string_literal: true

module CallableTree
  module Node
    module Internal
      include Node

      def children
        @children ||= []
      end

      def <<(callable)
        children <<
          if callable.is_a?(Node)
            callable.clone
          else
            External.proxify(callable)
          end
          .tap { |node| node.send(:parent=, self) }

        self
      end

      def append(*callables)
        callables.each { |callable| self.<<(callable) }
        self
      end

      def match?(_input = nil, **_options)
        !children.empty?
      end

      def call(input = nil, **options)
        children
          .lazy
          .map { |node| Input.new(input, options, node) }
          .select { |input| input.valid? }
          .map { |input| input.call }
          .select { |output| output.valid? }
          .map { |output| output.call }
          .first
      end

      class Input < BasicObject
        def initialize(value, options, node)
          @value = value
          @options = options
          @node = node
        end

        def valid?
          @node.match?(@value, **@options)
        end

        def call
          value = @node.call(@value, **@options)
          Output.new(value, @options, @node)
        end
      end

      class Output < BasicObject
        def initialize(value, options, node)
          @value = value
          @options = options
          @node = node
        end

        def valid?
          @node.terminate?(@value, **@options)
        end

        def call
          @value
        end
      end

      private_constant :Input, :Output

      private

      attr_writer :children

      def initialize_copy(_node)
        super
        self.children = children.map do |node|
          node.clone.tap { |new_node| new_node.send(:parent=, self) }
        end
      end
    end
  end
end

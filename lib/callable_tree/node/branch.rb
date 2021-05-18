# frozen_string_literal: true

module CallableTree
  module Node
    module Branch
      attr_reader :parent

      def ancestors
        ::Enumerator.new do |y|
          node = self
          while node = node&.parent
            y << node
          end
        end
      end

      def routes
        ::Enumerator.new do |y|
          y << self.class
          ancestors.each { |node| y << node.class }
        end
      end

      def depth
        parent.nil? ? 0 : parent.depth + 1
      end

      private

      attr_writer :parent
    end

    private_constant :Branch
  end
end

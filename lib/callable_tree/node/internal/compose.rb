# frozen_string_literal: true

module CallableTree
  module Node
    module Internal
      class Compose
        def call(nodes, input:, options:)
          nodes.reduce(input) do |input, node|
            if node.match?(input, **options)
              node.call(input, **options)
            else
              input
            end
          end
        end
      end
    end
  end
end

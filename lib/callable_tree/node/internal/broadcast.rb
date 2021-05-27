# frozen_string_literal: true

module CallableTree
  module Node
    module Internal
      class Broadcast
        def call(nodes, input:, options:)
          nodes.map do |node|
            if node.match?(input, **options)
              node.call(input, **options)
            else
              nil
            end
          end
        end
      end
    end
  end
end

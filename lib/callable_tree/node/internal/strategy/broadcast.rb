# frozen_string_literal: true

module CallableTree
  module Node
    module Internal
      module Strategy
        class Broadcast
          def call(nodes, input:, options:)
            nodes.map do |node|
              node.call(input, **options) if node.match?(input, **options)
            end
          end
        end
      end
    end
  end
end

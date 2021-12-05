# frozen_string_literal: true

module CallableTree
  module Node
    module Internal
      module Strategy
        class Broadcast
          def call(nodes, *inputs, **options)
            nodes.map do |node|
              node.call(*inputs, **options) if node.match?(*inputs, **options)
            end
          end
        end
      end
    end
  end
end

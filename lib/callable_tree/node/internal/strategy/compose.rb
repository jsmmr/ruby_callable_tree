# frozen_string_literal: true

module CallableTree
  module Node
    module Internal
      module Strategy
        class Compose
          def call(nodes, *inputs, **options)
            head, *tail = inputs
            nodes.reduce(head) do |input, node|
              inputs = [input, *tail]
              if node.match?(*inputs, **options)
                node.call(*inputs, **options)
              else
                input
              end
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module CallableTree
  module Node
    module Internal
      module Strategy
        class Broadcast
          include Strategy

          def initialize(terminable: false)
            self.terminable = terminable
          end

          def call(nodes, *inputs, **options)
            nodes.reduce([]) do |outputs, node|
              output = (node.call(*inputs, **options) if node.match?(*inputs, **options))
              outputs << output

              if terminator.call(node, output, *inputs, **options)
                break outputs
              else
                outputs
              end
            end
          end
        end
      end
    end
  end
end

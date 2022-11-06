# frozen_string_literal: true

module CallableTree
  module Node
    module Internal
      module Strategy
        class Broadcast
          include Strategy

          def initialize(terminable: false)
            self.terminable = terminable
            @terminator =
              if terminable
                proc { |node, output, *inputs, **options| node.terminate?(output, *inputs, **options) }
              else
                proc { false }
              end
          end

          def call(nodes, *inputs, **options)
            nodes.reduce([]) do |outputs, node|
              output = (node.call(*inputs, **options) if node.match?(*inputs, **options))
              outputs << output

              if @terminator.call(node, output, *inputs, **options)
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

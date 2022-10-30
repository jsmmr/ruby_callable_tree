# frozen_string_literal: true

module CallableTree
  module Node
    module Internal
      module Strategy
        class Compose
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
            head, *tail = inputs
            nodes.reduce(head) do |input, node|
              if node.match?(input, *tail, **options)
                output = node.call(input, *tail, **options)
                break output if @terminator.call(node, output, input, *tail, **options)

                output
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

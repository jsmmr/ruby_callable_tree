# frozen_string_literal: true

module CallableTree
  module Node
    module Internal
      module Strategy
        class Compose
          include Strategy

          def initialize(matchable: true, terminable: false)
            self.matchable = matchable
            self.terminable = terminable
          end

          def call(nodes, *inputs, **options)
            head, *tail = inputs
            nodes.reduce(head) do |input, node|
              if matcher.call(node, input, *tail, **options)
                output = node.call(input, *tail, **options)
                break output if terminator.call(node, output, input, *tail, **options)

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

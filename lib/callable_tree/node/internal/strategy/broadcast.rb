# frozen_string_literal: true

module CallableTree
  module Node
    module Internal
      module Strategy
        class Broadcast
          include Strategy

          def initialize(matchable: true, terminable: false)
            self.matchable = matchable
            self.terminable = terminable
          end

          def call(nodes, *inputs, **options)
            nodes.each_with_object([]) do |node, outputs|
              output = (node.call(*inputs, **options) if matcher.call(node, *inputs, **options))
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

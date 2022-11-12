# frozen_string_literal: true

module CallableTree
  module Node
    module Internal
      module Strategy
        class Seek
          include Strategy

          def initialize(terminable: true)
            self.terminable = terminable
          end

          def call(nodes, *inputs, **options)
            nodes
              .lazy
              .select { |node| node.match?(*inputs, **options) }
              .map do |node|
                output = node.call(*inputs, **options)
                terminated = terminator.call(node, output, *inputs, **options)
                [output, terminated]
              end
              .select { |_output, terminated| terminated }
              .map { |output, _terminated| output }
              .first
          end
        end
      end
    end
  end
end

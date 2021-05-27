# frozen_string_literal: true

module CallableTree
  module Node
    module Internal
      class Seek
        def call(nodes, input:, options:)
          nodes
            .lazy
            .select { |node| node.match?(input, **options) }
            .map do |node|
              output = node.call(input, **options)
              terminated = node.terminate?(output, **options)
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

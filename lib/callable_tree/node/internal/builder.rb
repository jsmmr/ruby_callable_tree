# frozen_string_literal: true

module CallableTree
  module Node
    module Internal
      class Builder
        include Node::Builder

        def build
          super(node_type: Internal)
        end

        private

        def validate(matcher:, caller:, terminator:)
          # noop
        end
      end
    end
  end
end

# frozen_string_literal: true

module CallableTree
  module Node
    module External
      class Builder
        include Node::Builder

        class Error < StandardError; end

        def build
          super(node_type: External)
        end

        private

        def validate(matcher:, caller:, terminator:)
          raise Error 'caller is required' unless caller
        end
      end
    end
  end
end

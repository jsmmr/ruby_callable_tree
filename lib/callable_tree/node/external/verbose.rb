# frozen_string_literal: true

module CallableTree
  module Node
    module External
      # TODO: Add :inputs
      Output = Struct.new(:value, :options, :routes)

      module Verbose
        def verbosified?
          true
        end

        def call(*inputs, **options)
          output = super(*inputs, **options)
          routes = self.routes

          Output.new(output, options, routes)
        end
      end

      private_constant :Verbose
    end
  end
end

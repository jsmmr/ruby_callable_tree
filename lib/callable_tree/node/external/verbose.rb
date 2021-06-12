# frozen_string_literal: true

module CallableTree
  module Node
    module External
      Output = Struct.new(:value, :options, :routes)

      module Verbose
        def verbosified?
          true
        end

        def call(input = nil, **options)
          output = super(input, **options)
          routes = self.routes

          Output.new(output, options, routes)
        end
      end

      private_constant :Verbose
    end
  end
end

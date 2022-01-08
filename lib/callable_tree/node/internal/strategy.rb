# frozen_string_literal: true

module CallableTree
  module Node
    module Internal
      module Strategy
        def call(_nodes, *_inputs, **_options)
          raise ::CallableTree::Error, 'Not implemented'
        end

        def name
          @name ||= self.class.name.split('::').last.downcase.to_sym
        end

        def ==(other)
          name == other.name
        end

        def eql?(other)
          instance_of?(other.class) && self == other
        end

        def hash
          self.class.name.hash
        end
      end
    end
  end
end

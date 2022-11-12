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
          name == other.name && terminable? == other.terminable?
        end

        def eql?(other)
          instance_of?(other.class) && self == other
        end

        def hash
          [self.class.name, terminable].join('-').hash
        end

        def terminable?
          terminable
        end

        private

        attr_accessor :terminable

        def terminator
          @terminator ||=
            if terminable
              proc { |node, output, *inputs, **options| node.terminate?(output, *inputs, **options) }
            else
              proc { false }
            end
        end
      end
    end
  end
end

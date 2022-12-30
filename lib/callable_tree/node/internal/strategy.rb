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
          name == other.name && matchable? == other.matchable? && terminable? == other.terminable?
        end

        def eql?(other)
          instance_of?(other.class) && self == other
        end

        def hash
          [self.class.name, matchable, terminable].join('-').hash
        end

        def matchable?
          matchable
        end

        def terminable?
          terminable
        end

        private

        attr_accessor :matchable, :terminable

        def matcher
          @matcher ||=
            if matchable
              proc { |node, *inputs, **options| node.match?(*inputs, **options) }
            else
              proc { false }
            end
        end

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

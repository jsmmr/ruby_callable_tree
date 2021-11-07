# frozen_string_literal: true

module CallableTree
  module Node
    attr_reader :parent

    def root?
      parent.nil?
    end

    def ancestors
      ::Enumerator.new do |y|
        node = self
        loop do
          y << node
          break unless node = node.parent
        end
      end
    end

    def routes
      ancestors.map(&:identity)
    end

    def identity
      self.class
    end

    def depth
      root? ? 0 : parent.depth + 1
    end

    def outline
      raise ::CallableTree::Error, 'Not implemented'
    end

    def match?(_input = nil, **_options)
      true
    end

    def call(_input = nil, **_options)
      raise ::CallableTree::Error, 'Not implemented'
    end

    def terminate?(output = nil, **_options)
      !output.nil?
    end

    private

    attr_writer :parent
  end
end

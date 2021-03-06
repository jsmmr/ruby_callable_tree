# frozen_string_literal: true

class IdNode
  include CallableTree::Node::Internal

  def initialize(id)
    @id = id
  end

  def identity
    @id
  end
end

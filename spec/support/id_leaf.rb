class IdLeaf
  include CallableTree::Node::External

  def initialize(id)
    @id = id
  end

  def identity
    @id
  end

  def call(input, *, **)
    input
  end
end

class NamedInternalNode
  include CallableTree::Node::Internal

  def initialize(name)
    @name = name
  end

  def identity
    @name
  end
end

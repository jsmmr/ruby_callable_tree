class NamedExternalNode
  include CallableTree::Node::External

  def initialize(name)
    @name = name
  end

  def identity
    @name
  end

  def call(input = nil)
    input
  end
end

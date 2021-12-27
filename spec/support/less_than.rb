# frozen_string_literal: true

class LessThan
  include CallableTree::Node::Internal

  def initialize(num)
    @num = num
  end

  def match?(input, *, **)
    super && input < @num
  end
end

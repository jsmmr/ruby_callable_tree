# frozen_string_literal: true

require 'callable_tree'

module Node
  class LessThan
    include CallableTree::Node::Internal

    def initialize(num)
      @num = num
    end

    def match?(input)
      super && input < @num
    end
  end
end

tree = CallableTree::Node::Root.new.composable.append(
  Node::LessThan.new(5).composable.append(
    proc { |input| input * 2 }, # anonymous external node
    proc { |input| input + 1 }  # anonymous external node
  ),
  Node::LessThan.new(10).composable.append(
    proc { |input| input * 3 }, # anonymous external node
    proc { |input| input - 1 }  # anonymous external node
  )
)

(0..10).each do |input|
  output = tree.call(input)
  puts "#{input} -> #{output}"
end

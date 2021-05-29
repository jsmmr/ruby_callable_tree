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

tree = CallableTree::Node::Root.new.append(
  Node::LessThan.new(5).append(
    proc { |input| input * 2 }, # anonymous external node
    proc { |input| input + 1 }  # anonymous external node
  ).compose,
  Node::LessThan.new(10).append(
    proc { |input| input * 3 }, # anonymous external node
    proc { |input| input - 1 }  # anonymous external node
  ).compose
).compose

(0..10).each do |input|
  output = tree.call(input)
  puts "#{input} -> #{output}"
end

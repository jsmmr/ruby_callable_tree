# frozen_string_literal: true

require 'callable_tree'

less_than = proc do |num|
  # The following block call is equivalent to calling `super` in the class style.
  proc { |input, &block| block.call(input) && input < num }
end

LessThan5 =
  CallableTree::Node::Internal::Builder
  .new
  .matcher(&less_than.call(5))
  .build

LessThan10 =
  CallableTree::Node::Internal::Builder
  .new
  .matcher(&less_than.call(10))
  .build

add = proc do |num|
  proc { |input| input + num }
end

Add1 =
  CallableTree::Node::External::Builder
  .new
  .caller(&add.call(1))
  .build

subtract = proc do |num|
  proc { |input| input - num }
end

Subtract1 =
  CallableTree::Node::External::Builder
  .new
  .caller(&subtract.call(1))
  .build

multiply = proc do |num|
  proc { |input| input * num }
end

Multiply2 =
  CallableTree::Node::External::Builder
  .new
  .caller(&multiply.call(2))
  .build

Multiply3 =
  CallableTree::Node::External::Builder
  .new
  .caller(&multiply.call(3))
  .build

tree = CallableTree::Node::Root.new.broadcastable.append(
  LessThan5.new.broadcastable.append(
    Multiply2.new,
    Add1.new
  ),
  LessThan10.new.broadcastable.append(
    Multiply3.new,
    Subtract1.new
  )
)

(0..10).each do |input|
  output = tree.call(input)
  puts "#{input} -> #{output}"
end

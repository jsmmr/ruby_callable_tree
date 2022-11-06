# frozen_string_literal: true

def build_less_than(num)
  CallableTree::Node::Internal::Builder
    .new
    .identifier { "LessThan#{num}" }
    .matcher { |input, *, **, &block| block.call(input) && input < num }
    .hookable
    .build
end

def build_formatter(format)
  CallableTree::Node::External::Builder
    .new
    .identifier { "#{format}Formatter" }
    .caller { |input, *, **| format % input }
    .hookable
    .build
end

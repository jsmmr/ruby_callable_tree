# frozen_string_literal: true

require_relative '../../lib/callable_tree'

# Composable example using Factory style with pre-defined procs
# Output of one node becomes input to the next (pipeline)

# === Behavior Definitions ===

less_than_5_matcher = ->(input, **, &original) { original.call(input) && input < 5 }
less_than_10_matcher = ->(input, **, &original) { original.call(input) && input < 10 }

multiply_2_caller = ->(input, **) { input * 2 }
add_1_caller = ->(input, **) { input + 1 }
multiply_3_caller = ->(input, **) { input * 3 }
subtract_1_caller = ->(input, **) { input - 1 }

# === Tree Structure ===

tree = CallableTree::Node::Root.new.composable.append(
  CallableTree::Node::Internal.create(matcher: less_than_5_matcher).composable.append(
    CallableTree::Node::External.create(caller: multiply_2_caller),
    CallableTree::Node::External.create(caller: add_1_caller)
  ),
  CallableTree::Node::Internal.create(matcher: less_than_10_matcher).composable.append(
    CallableTree::Node::External.create(caller: multiply_3_caller),
    CallableTree::Node::External.create(caller: subtract_1_caller)
  )
)

# === Execution ===

(0..10).each do |input|
  output = tree.call(input)
  puts "#{input} -> #{output}"
end

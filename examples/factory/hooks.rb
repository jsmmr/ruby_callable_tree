# frozen_string_literal: true

require_relative '../../lib/callable_tree'
# require 'callable_tree'

# Hooks example using Factory style with pre-defined procs
# Demonstrates before/around/after callbacks on matcher, caller, and terminator

# === Behavior Definitions ===

external_caller = lambda do |input, **_options|
  puts "external input: #{input}"
  input * 2
end

# === Tree Structure with Hooks ===

CallableTree::Node::Root.new.append(
  CallableTree::Node::Internal.create(hookable: true)
    .append(external_caller)
    .before_matcher do |input, **_options|
      puts "before_matcher input: #{input}"
      input + 1
    end
    .around_matcher do |input, **_options, &block|
      puts "around_matcher input: #{input}"
      matched = block.call
      puts "around_matcher matched: #{matched}"
      !matched
    end
    .after_matcher do |matched, **_options|
      puts "after_matcher matched: #{matched}"
      !matched
    end
    .before_caller do |input, **_options|
      puts "before_caller input: #{input}"
      input + 1
    end
    .around_caller do |input, **_options, &block|
      puts "around_caller input: #{input}"
      output = block.call
      puts "around_caller output: #{output}"
      output * input
    end
    .after_caller do |output, **_options|
      puts "after_caller output: #{output}"
      output * 2
    end
    .before_terminator do |output, *_inputs, **_options|
      puts "before_terminator output: #{output}"
      output + 1
    end
    .around_terminator do |output, *_inputs, **_options, &block|
      puts "around_terminator output: #{output}"
      terminated = block.call
      puts "around_terminator terminated: #{terminated}"
      !terminated
    end
    .after_terminator do |terminated, **_options|
      puts "after_terminator terminated: #{terminated}"
      !terminated
    end
).tap do |tree|
  options = { foo: :bar }
  output = tree.call(1, **options)
  puts "result: #{output}"
end

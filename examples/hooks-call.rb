require 'callable_tree'

module Node
  class HooksSample
    include CallableTree::Node::Internal
    prepend CallableTree::Node::Hooks::Call
  end
end

Node::HooksSample.new
  .before_call do |input, **options|
    puts "before_call input: #{input}";
    input + 1
  end
  .append(
    # anonymous external node
    lambda do |input, **options|
      puts "external input: #{input}"
      input * 2
    end
  )
  .around_call do |input, **options, &block|
    puts "around_call input: #{input}"
    output = block.call
    puts "around_call output: #{output}"
    output * input
  end
  .after_call do |output, **options|
    puts "after_call output: #{output}"
    output * 2
  end
  .tap do |tree|
    options = { foo: :bar }
    output = tree.call(1, **options)
    puts "result: #{output}"
  end

# CallableTree

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'callable_tree'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install callable_tree

## Usage

- `CallableTree::Node::Internal`
  - This `module` is used to define a node that can have child nodes.
- `CallableTree::Node::External`
  - This `module` is used to define a leaf node that cannot have child nodes.
- `CallableTree::Node::Root`
  - This `class` includes `CallableTree::Node::Internal`. When there is no need to customize the internal node, use this `class`.

Builds a tree by linking instances of the nodes. The `call` method of the node where the `match?` method returns a truthy value is called in a chain from the root node to the leaf node.
If the `call` method returns a value other than `nil`, the next sibling node does not be called. This behavior is changeable by overriding the `terminate?` method.

### Basic

`examples/example1.rb`:
```ruby
module Node
  module JSON
    class Parser
      include CallableTree::Node::Internal

      def match?(input, **options)
        File.extname(input) == '.json'
      end

      # If there is need to convert the input value for
      # child nodes, override the `call` method.
      def call(input, **options)
        File.open(input) do |file|
          json = ::JSON.load(file)
          super(json, **options)
        end
      end

      # If a returned value of the `call` method is `nil`,
      # but there is no need to call the sibling nodes,
      # override the `terminate?` method to return `true`.
      def terminate?(output, **options)
        true
      end
    end

    class Scraper
      include CallableTree::Node::External

      def initialize(type:)
        @type = type
      end

      def match?(input, **options)
        !!input[@type.to_s]
      end

      def call(input, **options)
        input[@type.to_s]
          .map { |element| [element['name'], element['emoji']] }
          .to_h
      end
    end
  end

  module XML
    class Parser
      include CallableTree::Node::Internal

      def match?(input, **options)
        File.extname(input) == '.xml'
      end

      # If there is need to convert the input value for
      # child nodes, override the `call` method.
      def call(input, **options)
        File.open(input) do |file|
          super(REXML::Document.new(file), **options)
        end
      end

      # If a returned value of the `call` method is `nil`,
      # but there is no need to call the sibling nodes,
      # override the `terminate?` method to return `true`.
      def terminate?(output, **options)
        true
      end
    end

    class Scraper
      include CallableTree::Node::External

      def initialize(type:)
        @type = type
      end

      def match?(input, **options)
        !input.get_elements("//#{@type}").empty?
      end

      def call(input, **options)
        input
          .get_elements("//#{@type}")
          .first
          .map { |element| [element['name'], element['emoji']] }
          .to_h
      end
    end
  end
end

tree = CallableTree::Node::Root.new.append(
  Node::JSON::Parser.new.append(
    Node::JSON::Scraper.new(type: :animals),
    Node::JSON::Scraper.new(type: :fruits)
  ),
  Node::XML::Parser.new.append(
    Node::XML::Scraper.new(type: :animals),
    Node::XML::Scraper.new(type: :fruits)
  )
)

Dir.glob(__dir__ + '/docs/*') do |file|
  options = { foo: :bar }
  pp tree.call(file, **options)
  puts '---'
end
```

Run `examples/example1.rb`:
```sh
% ruby examples/example1.rb
{"Dog"=>"🐶", "Cat"=>"🐱"}
---
{"Dog"=>"🐶", "Cat"=>"🐱"}
---
{"Red Apple"=>"🍎", "Green Apple"=>"🍏"}
---
{"Red Apple"=>"🍎", "Green Apple"=>"🍏"}
---
```

### Advanced

#### `CallableTree::Node::External#verbosify`

If you want verbose result, call it.

`examples/example2.rb`:
```ruby
...

tree = CallableTree::Node::Root.new.append(
  Node::JSON::Parser.new.append(
    Node::JSON::Scraper.new(type: :animals).verbosify,
    Node::JSON::Scraper.new(type: :fruits).verbosify
  ),
  Node::XML::Parser.new.append(
    Node::XML::Scraper.new(type: :animals).verbosify,
    Node::XML::Scraper.new(type: :fruits).verbosify
  )
)

...
```

Run `examples/example2.rb`:
```sh
% ruby examples/example2.rb
#<struct CallableTree::Node::External::Output
 value={"Dog"=>"🐶", "Cat"=>"🐱"},
 options={:foo=>:bar},
 routes=[Node::JSON::Scraper, Node::JSON::Parser, CallableTree::Node::Root]>
---
#<struct CallableTree::Node::External::Output
 value={"Dog"=>"🐶", "Cat"=>"🐱"},
 options={:foo=>:bar},
 routes=[Node::XML::Scraper, Node::XML::Parser, CallableTree::Node::Root]>
---
#<struct CallableTree::Node::External::Output
 value={"Red Apple"=>"🍎", "Green Apple"=>"🍏"},
 options={:foo=>:bar},
 routes=[Node::JSON::Scraper, Node::JSON::Parser, CallableTree::Node::Root]>
---
#<struct CallableTree::Node::External::Output
 value={"Red Apple"=>"🍎", "Green Apple"=>"🍏"},
 options={:foo=>:bar},
 routes=[Node::XML::Scraper, Node::XML::Parser, CallableTree::Node::Root]>
---
```

At first glance, this looks good, but the `routes` are ambiguous when there are multiple nodes of the same class.
You can work around it by overriding the `identity` method of the node.

#### `CallableTree::Node#identity`

If you want to customize the node identity, override it.

`examples/example3.rb`:
```ruby
module Node
  class Identity
    attr_reader :klass, :type

    def initialize(klass:, type:)
      @klass = klass
      @type = type
    end

    def to_s
      "#{klass}(#{type})"
    end
  end

  module JSON
    ...

    class Scraper
      include CallableTree::Node::External

      def initialize(type:)
        @type = type
      end

      def identity
        Identity.new(klass: super, type: @type)
      end

      ...
    end
  end

  module XML
     ...

    class Scraper
      include CallableTree::Node::External

      def initialize(type:)
        @type = type
      end

      def identity
        Identity.new(klass: super, type: @type)
      end

      ...
    end
  end
end

...
```

Run `examples/example3.rb`:
```sh
% ruby examples/example3.rb
#<struct CallableTree::Node::External::Output
 value={"Dog"=>"🐶", "Cat"=>"🐱"},
 options={:foo=>:bar},
 routes=
  [#<Node::Identity:0x00007fb4378a9718
    @klass=Node::JSON::Scraper,
    @type=:animals>,
   Node::JSON::Parser,
   CallableTree::Node::Root]>
---
#<struct CallableTree::Node::External::Output
 value={"Dog"=>"🐶", "Cat"=>"🐱"},
 options={:foo=>:bar},
 routes=
  [#<Node::Identity:0x00007fb41002b6d0
    @klass=Node::XML::Scraper,
    @type=:animals>,
   Node::XML::Parser,
   CallableTree::Node::Root]>
---
#<struct CallableTree::Node::External::Output
 value={"Red Apple"=>"🍎", "Green Apple"=>"🍏"},
 options={:foo=>:bar},
 routes=
  [#<Node::Identity:0x00007fb41001b3e8
    @klass=Node::JSON::Scraper,
    @type=:fruits>,
   Node::JSON::Parser,
   CallableTree::Node::Root]>
---
#<struct CallableTree::Node::External::Output
 value={"Red Apple"=>"🍎", "Green Apple"=>"🍏"},
 options={:foo=>:bar},
 routes=
  [#<Node::Identity:0x00007fb410049d38
    @klass=Node::XML::Scraper,
    @type=:fruits>,
   Node::XML::Parser,
   CallableTree::Node::Root]>
---
```

#### Logging

This is an example of logging.

`examples/example4.rb`:
```ruby
module Node
  module Logging
    INDENT_SIZE = 2
    BLANK = ' '.freeze

    module Match
      LIST_STYLE = '*'.freeze

      def match?(_input, **)
        super.tap do |matched|
          prefix = LIST_STYLE.rjust(self.depth * INDENT_SIZE - INDENT_SIZE + LIST_STYLE.length, BLANK)
          puts "#{prefix} #{self.identity}: [matched: #{matched}]"
        end
      end
    end

    module Call
      INPUT_LABEL  = 'Input :'.freeze
      OUTPUT_LABEL = 'Output:'.freeze

      def call(input, **)
        super.tap do |output|
          input_prefix = INPUT_LABEL.rjust(self.depth * INDENT_SIZE + INPUT_LABEL.length, BLANK)
          puts "#{input_prefix} #{input}"
          output_prefix = OUTPUT_LABEL.rjust(self.depth * INDENT_SIZE + OUTPUT_LABEL.length, BLANK)
          puts "#{output_prefix} #{output}"
        end
      end
    end
  end

  ...

  module JSON
    class Parser
      include CallableTree::Node::Internal
      prepend Logging::Match

      ...
    end

    class Scraper
      include CallableTree::Node::External
      prepend Logging::Match
      prepend Logging::Call

      ...
    end
  end

  module XML
    class Parser
      include CallableTree::Node::Internal
      prepend Logging::Match

      ...
    end

    class Scraper
      include CallableTree::Node::External
      prepend Logging::Match
      prepend Logging::Call

      ...
    end
  end
end

...
```

Run `examples/example4.rb`:
```sh
% ruby examples/example4.rb
* Node::JSON::Parser: [matched: true]
  * Node::JSON::Scraper(animals): [matched: true]
    Input : {"animals"=>[{"name"=>"Dog", "emoji"=>"🐶"}, {"name"=>"Cat", "emoji"=>"🐱"}]}
    Output: {"Dog"=>"🐶", "Cat"=>"🐱"}
#<struct CallableTree::Node::External::Output
 value={"Dog"=>"🐶", "Cat"=>"🐱"},
 options={:foo=>:bar},
 routes=
  [#<Node::Identity:0x00007ffd840347b8
    @klass=Node::JSON::Scraper,
    @type=:animals>,
   Node::JSON::Parser,
   CallableTree::Node::Root]>
---
* Node::JSON::Parser: [matched: false]
* Node::XML::Parser: [matched: true]
  * Node::XML::Scraper(animals): [matched: true]
    Input : <root><animals><animal emoji='🐶' name='Dog'/><animal emoji='🐱' name='Cat'/></animals></root>
    Output: {"Dog"=>"🐶", "Cat"=>"🐱"}
#<struct CallableTree::Node::External::Output
 value={"Dog"=>"🐶", "Cat"=>"🐱"},
 options={:foo=>:bar},
 routes=
  [#<Node::Identity:0x00007ffd7403f1f0
    @klass=Node::XML::Scraper,
    @type=:animals>,
   Node::XML::Parser,
   CallableTree::Node::Root]>
---
* Node::JSON::Parser: [matched: true]
  * Node::JSON::Scraper(animals): [matched: false]
  * Node::JSON::Scraper(fruits): [matched: true]
    Input : {"fruits"=>[{"name"=>"Red Apple", "emoji"=>"🍎"}, {"name"=>"Green Apple", "emoji"=>"🍏"}]}
    Output: {"Red Apple"=>"🍎", "Green Apple"=>"🍏"}
#<struct CallableTree::Node::External::Output
 value={"Red Apple"=>"🍎", "Green Apple"=>"🍏"},
 options={:foo=>:bar},
 routes=
  [#<Node::Identity:0x00007ffd8512bdf0
    @klass=Node::JSON::Scraper,
    @type=:fruits>,
   Node::JSON::Parser,
   CallableTree::Node::Root]>
---
* Node::JSON::Parser: [matched: false]
* Node::XML::Parser: [matched: true]
  * Node::XML::Scraper(animals): [matched: false]
  * Node::XML::Scraper(fruits): [matched: true]
    Input : <root><fruits><fruit emoji='🍎' name='Red Apple'/><fruit emoji='🍏' name='Green Apple'/></fruits></root>
    Output: {"Red Apple"=>"🍎", "Green Apple"=>"🍏"}
#<struct CallableTree::Node::External::Output
 value={"Red Apple"=>"🍎", "Green Apple"=>"🍏"},
 options={:foo=>:bar},
 routes=
  [#<Node::Identity:0x00007ffd8407a740
    @klass=Node::XML::Scraper,
    @type=:fruits>,
   Node::XML::Parser,
   CallableTree::Node::Root]>
---
```

#### `CallableTree::Node::Hooks::Call` (experimental)

`examples/example5.rb`:
```ruby
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
```

Run `examples/example5.rb`:
```sh
% ruby examples/example5.rb
before_call input: 1
external input: 2
around_call input: 2
around_call output: 4
after_call output: 8
result: 16
```

#### `CallableTree::Node::Internal#broadcast` (experimental)

If you want to call all child nodes of the internal node in order to output their results as array, call it. The `broadcast` strategy ignores the `terminate?` method of the nodes.

`examples/example6.rb`:
```ruby
...

tree = CallableTree::Node::Root.new.append(
  Node::JSON::Parser.new.append(
    Node::JSON::Scraper.new(type: :animals),
    Node::JSON::Scraper.new(type: :fruits)
  ).broadcast,
  Node::XML::Parser.new.append(
    Node::XML::Scraper.new(type: :animals),
    Node::XML::Scraper.new(type: :fruits)
  ).broadcast
)

...
```

Run `examples/example6.rb`:
```sh
% ruby examples/example6.rb
[{"Dog"=>"🐶", "Cat"=>"🐱"}, nil]
---
[{"Dog"=>"🐶", "Cat"=>"🐱"}, nil]
---
[nil, {"Red Apple"=>"🍎", "Green Apple"=>"🍏"}]
---
[nil, {"Red Apple"=>"🍎", "Green Apple"=>"🍏"}]
---
```

#### `CallableTree::Node::Internal#compose` (experimental)

If you want to call all child nodes of the internal node in order to input the output of the previous node to the next node and output a single result , call it. The `compose` strategy ignores the `terminate?` method of the nodes.

`examples/example7.rb`:
```ruby
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

```

Run `examples/example7.rb`:
```sh
% ruby examples/example7.rb
0 -> 2
1 -> 8
2 -> 14
3 -> 20
4 -> 26
5 -> 14
6 -> 17
7 -> 20
8 -> 23
9 -> 26
10 -> 10
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jsmmr/callable_tree.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

# CallableTree

[![build](https://github.com/jsmmr/ruby_callable_tree/actions/workflows/build.yml/badge.svg)](https://github.com/jsmmr/ruby_callable_tree/actions/workflows/build.yml)
[![CodeQL](https://github.com/jsmmr/ruby_callable_tree/actions/workflows/codeql-analysis.yml/badge.svg)](https://github.com/jsmmr/ruby_callable_tree/actions/workflows/codeql-analysis.yml)

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

Builds a tree by linking `CallableTree` node instances. The `call` methods of the nodes where the `match?` method returns a truthy value are called in a chain from the root node to the leaf node.

- `CallableTree::Node::Internal`
  - This `module` is used to define a node that can have child nodes. An instance of this node has several strategies (`seekable`, `broadcastable`, `composable`). The strategy can be changed by calling the method of the instance.
- `CallableTree::Node::External`
  - This `module` is used to define a leaf node that cannot have child nodes.
- `CallableTree::Node::Root`
  - This `class` includes `CallableTree::Node::Internal`. When there is no need to customize the internal node, use this `class`.

### Basic

There are two ways to define the nodes: class style and builder style (experimental).

#### `CallableTree::Node::Internal#seekable` (default strategy)

This strategy does not call the next sibling node if the `call` method of the current node returns a value other than `nil`. This behavior is changeable by overriding the `terminate?` method.

##### Class style

`examples/class/internal-seekable.rb`:
```ruby
module Node
  module JSON
    class Parser
      include CallableTree::Node::Internal

      def match?(input, **_options)
        File.extname(input) == '.json'
      end

      # If there is need to convert the input values for
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
      def terminate?(_output, *_inputs, **_options)
        true
      end
    end

    class Scraper
      include CallableTree::Node::External

      def initialize(type:)
        @type = type
      end

      def match?(input, **_options)
        !!input[@type.to_s]
      end

      def call(input, **_options)
        input[@type.to_s]
          .map { |element| [element['name'], element['emoji']] }
          .to_h
      end
    end
  end

  module XML
    class Parser
      include CallableTree::Node::Internal

      def match?(input, **_options)
        File.extname(input) == '.xml'
      end

      # If there is need to convert the input values for
      # child nodes, override the `call` method.
      def call(input, **options)
        File.open(input) do |file|
          super(REXML::Document.new(file), **options)
        end
      end

      # If a returned value of the `call` method is `nil`,
      # but there is no need to call the sibling nodes,
      # override the `terminate?` method to return `true`.
      def terminate?(_output, *_inputs, **_options)
        true
      end
    end

    class Scraper
      include CallableTree::Node::External

      def initialize(type:)
        @type = type
      end

      def match?(input, **_options)
        !input.get_elements("//#{@type}").empty?
      end

      def call(input, **_options)
        input
          .get_elements("//#{@type}")
          .first
          .map { |element| [element['name'], element['emoji']] }
          .to_h
      end
    end
  end
end

# The `seekable` method call can be omitted since it is the default strategy.
tree = CallableTree::Node::Root.new.seekable.append(
  Node::JSON::Parser.new.seekable.append(
    Node::JSON::Scraper.new(type: :animals),
    Node::JSON::Scraper.new(type: :fruits)
  ),
  Node::XML::Parser.new.seekable.append(
    Node::XML::Scraper.new(type: :animals),
    Node::XML::Scraper.new(type: :fruits)
  )
)

Dir.glob("#{__dir__}/docs/*") do |file|
  options = { foo: :bar }
  pp tree.call(file, **options)
  puts '---'
end
```

Run `examples/class/internal-seekable.rb`:
```sh
% ruby examples/class/internal-seekable.rb
{"Dog"=>"????", "Cat"=>"????"}
---
{"Dog"=>"????", "Cat"=>"????"}
---
{"Red Apple"=>"????", "Green Apple"=>"????"}
---
{"Red Apple"=>"????", "Green Apple"=>"????"}
---
```

##### Builder style (experimental)

`examples/builder/internal-seekable.rb`:
```ruby
JSONParser =
  CallableTree::Node::Internal::Builder
  .new
  .matcher do |input, **_options|
    File.extname(input) == '.json'
  end
  .caller do |input, **options, &block|
    File.open(input) do |file|
      json = ::JSON.load(file)
      # The following block call is equivalent to calling `super` in the class style.
      block.call(json, **options)
    end
  end
  .terminator do
    true
  end
  .build

XMLParser =
  CallableTree::Node::Internal::Builder
  .new
  .matcher do |input, **_options|
    File.extname(input) == '.xml'
  end
  .caller do |input, **options, &block|
    File.open(input) do |file|
      # The following block call is equivalent to calling `super` in the class style.
      block.call(REXML::Document.new(file), **options)
    end
  end
  .terminator do
    true
  end
  .build

def build_json_scraper(type)
  CallableTree::Node::External::Builder
    .new
    .matcher do |input, **_options|
      !!input[type.to_s]
    end
    .caller do |input, **_options|
      input[type.to_s]
        .map { |element| [element['name'], element['emoji']] }
        .to_h
    end
    .build
end

AnimalsJSONScraper = build_json_scraper(:animals)
FruitsJSONScraper = build_json_scraper(:fruits)

def build_xml_scraper(type)
  CallableTree::Node::External::Builder
    .new
    .matcher do |input, **_options|
      !input.get_elements("//#{type}").empty?
    end
    .caller do |input, **_options|
      input
        .get_elements("//#{type}")
        .first
        .map { |element| [element['name'], element['emoji']] }
        .to_h
    end
    .build
end

AnimalsXMLScraper = build_xml_scraper(:animals)
FruitsXMLScraper = build_xml_scraper(:fruits)

tree = CallableTree::Node::Root.new.seekable.append(
  JSONParser.new.seekable.append(
    AnimalsJSONScraper.new,
    FruitsJSONScraper.new
  ),
  XMLParser.new.seekable.append(
    AnimalsXMLScraper.new,
    FruitsXMLScraper.new
  )
)

Dir.glob("#{__dir__}/../docs/*") do |file|
  options = { foo: :bar }
  pp tree.call(file, **options)
  puts '---'
end
```

Run `examples/builder/internal-seekable.rb`:
```sh
% ruby examples/builder/internal-seekable.rb
{"Dog"=>"????", "Cat"=>"????"}
---
{"Dog"=>"????", "Cat"=>"????"}
---
{"Red Apple"=>"????", "Green Apple"=>"????"}
---
{"Red Apple"=>"????", "Green Apple"=>"????"}
---
```

#### `CallableTree::Node::Internal#broadcastable`

This strategy calls all child nodes of the internal node and ignores their `terminate?` methods, and then outputs their results as array.

##### Class style

`examples/class/internal-broadcastable.rb`:
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

tree = CallableTree::Node::Root.new.broadcastable.append(
  Node::LessThan.new(5).broadcastable.append(
    ->(input) { input * 2 }, # anonymous external node
    ->(input) { input + 1 }  # anonymous external node
  ),
  Node::LessThan.new(10).broadcastable.append(
    ->(input) { input * 3 }, # anonymous external node
    ->(input) { input - 1 }  # anonymous external node
  )
)

(0..10).each do |input|
  output = tree.call(input)
  puts "#{input} -> #{output}"
end

```

Run `examples/class/internal-broadcastable.rb`:
```sh
% ruby examples/class/internal-broadcastable.rb
0 -> [[0, 1], [0, -1]]
1 -> [[2, 2], [3, 0]]
2 -> [[4, 3], [6, 1]]
3 -> [[6, 4], [9, 2]]
4 -> [[8, 5], [12, 3]]
5 -> [nil, [15, 4]]
6 -> [nil, [18, 5]]
7 -> [nil, [21, 6]]
8 -> [nil, [24, 7]]
9 -> [nil, [27, 8]]
10 -> [nil, nil]
```

##### Builder style (experimental)

`examples/builder/internal-broadcastable.rb`:
```ruby
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
```

Run `examples/builder/internal-broadcastable.rb`:
```sh
% ruby examples/builder/internal-broadcastable.rb
0 -> [[0, 1], [0, -1]]
1 -> [[2, 2], [3, 0]]
2 -> [[4, 3], [6, 1]]
3 -> [[6, 4], [9, 2]]
4 -> [[8, 5], [12, 3]]
5 -> [nil, [15, 4]]
6 -> [nil, [18, 5]]
7 -> [nil, [21, 6]]
8 -> [nil, [24, 7]]
9 -> [nil, [27, 8]]
10 -> [nil, nil]
```

#### `CallableTree::Node::Internal#composable`

This strategy calls all child nodes of the internal node in order to input the output of the previous node to the next node and ignores their `terminate?` methods, and then outputs a single result.

##### Class style

`examples/class/internal-composable.rb`:
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

```

Run `examples/class/internal-composable.rb`:
```sh
% ruby examples/class/internal-composable.rb
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

##### Builder style (experimental)

`examples/builder/internal-composable.rb`:
```ruby
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

tree = CallableTree::Node::Root.new.composable.append(
  LessThan5.new.composable.append(
    Multiply2.new,
    Add1.new
  ),
  LessThan10.new.composable.append(
    Multiply3.new,
    Subtract1.new
  )
)

(0..10).each do |input|
  output = tree.call(input)
  puts "#{input} -> #{output}"
end
```

Run `examples/builder/internal-composable.rb`:
```sh
% ruby examples/builder/internal-composable.rb
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

### Advanced

#### `CallableTree::Node::External#verbosify`

If you want verbose output results, call this method.

`examples/class/external-verbosify.rb`:
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

Run `examples/class/external-verbosify.rb`:
```sh
% ruby examples/class/external-verbosify.rb
#<struct CallableTree::Node::External::Output
 value={"Dog"=>"????", "Cat"=>"????"},
 options={:foo=>:bar},
 routes=[Node::JSON::Scraper, Node::JSON::Parser, CallableTree::Node::Root]>
---
#<struct CallableTree::Node::External::Output
 value={"Dog"=>"????", "Cat"=>"????"},
 options={:foo=>:bar},
 routes=[Node::XML::Scraper, Node::XML::Parser, CallableTree::Node::Root]>
---
#<struct CallableTree::Node::External::Output
 value={"Red Apple"=>"????", "Green Apple"=>"????"},
 options={:foo=>:bar},
 routes=[Node::JSON::Scraper, Node::JSON::Parser, CallableTree::Node::Root]>
---
#<struct CallableTree::Node::External::Output
 value={"Red Apple"=>"????", "Green Apple"=>"????"},
 options={:foo=>:bar},
 routes=[Node::XML::Scraper, Node::XML::Parser, CallableTree::Node::Root]>
---
```

At first glance, this looks good, but the `routes` are ambiguous when there are multiple nodes of the same class.
You can work around it by overriding the `identity` method of the node.

#### `CallableTree::Node#identity`

If you want to customize the node identity, override this method.

`examples/class/identity.rb`:
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

Run `examples/class/identity.rb`:
```sh
% ruby examples/class/identity.rb
#<struct CallableTree::Node::External::Output
 value={"Dog"=>"????", "Cat"=>"????"},
 options={:foo=>:bar},
 routes=
  [#<Node::Identity:0x00007fb4378a9718
    @klass=Node::JSON::Scraper,
    @type=:animals>,
   Node::JSON::Parser,
   CallableTree::Node::Root]>
---
#<struct CallableTree::Node::External::Output
 value={"Dog"=>"????", "Cat"=>"????"},
 options={:foo=>:bar},
 routes=
  [#<Node::Identity:0x00007fb41002b6d0
    @klass=Node::XML::Scraper,
    @type=:animals>,
   Node::XML::Parser,
   CallableTree::Node::Root]>
---
#<struct CallableTree::Node::External::Output
 value={"Red Apple"=>"????", "Green Apple"=>"????"},
 options={:foo=>:bar},
 routes=
  [#<Node::Identity:0x00007fb41001b3e8
    @klass=Node::JSON::Scraper,
    @type=:fruits>,
   Node::JSON::Parser,
   CallableTree::Node::Root]>
---
#<struct CallableTree::Node::External::Output
 value={"Red Apple"=>"????", "Green Apple"=>"????"},
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

`examples/class/logging.rb`:
```ruby
module Node
  ...

  module JSON
    class Parser
      include CallableTree::Node::Internal
      prepend CallableTree::Node::Hooks::Matcher

      ...
    end

    class Scraper
      include CallableTree::Node::External
      prepend CallableTree::Node::Hooks::Matcher
      prepend CallableTree::Node::Hooks::Caller

      ...
    end
  end

  module XML
    class Parser
      include CallableTree::Node::Internal
      prepend CallableTree::Node::Hooks::Matcher

      ...
    end

    class Scraper
      include CallableTree::Node::External
      prepend CallableTree::Node::Hooks::Matcher
      prepend CallableTree::Node::Hooks::Caller

      ...
    end
  end
end

module Logging
  INDENT_SIZE = 2
  BLANK = ' '
  LIST_STYLE = '*'
  INPUT_LABEL  = 'Input :'
  OUTPUT_LABEL = 'Output:'

  def self.loggable(node)
    node.after_matcher! do |matched, _node_:, **|
      prefix = LIST_STYLE.rjust(_node_.depth * INDENT_SIZE - INDENT_SIZE + LIST_STYLE.length, BLANK)
      puts "#{prefix} #{_node_.identity}: [matched: #{matched}]"
      matched
    end

    if node.external?
      node
        .before_caller! do |input, *, _node_:, **|
          input_prefix = INPUT_LABEL.rjust(_node_.depth * INDENT_SIZE + INPUT_LABEL.length, BLANK)
          puts "#{input_prefix} #{input}"
          input
        end
        .after_caller! do |output, _node_:, **|
          output_prefix = OUTPUT_LABEL.rjust(_node_.depth * INDENT_SIZE + OUTPUT_LABEL.length, BLANK)
          puts "#{output_prefix} #{output}"
          output
        end
    end
  end
end

loggable = Logging.method(:loggable)

tree = CallableTree::Node::Root.new.append(
  Node::JSON::Parser.new.tap(&loggable).append(
    Node::JSON::Scraper.new(type: :animals).tap(&loggable).verbosify,
    Node::JSON::Scraper.new(type: :fruits).tap(&loggable).verbosify
  ),
  Node::XML::Parser.new.tap(&loggable).append(
    Node::XML::Scraper.new(type: :animals).tap(&loggable).verbosify,
    Node::XML::Scraper.new(type: :fruits).tap(&loggable).verbosify
  )
)

...
```

Also, see `examples/class/hooks.rb` for detail about `CallableTree::Node::Hooks::*`.

Run `examples/class/logging.rb`:
```sh
% ruby examples/class/logging.rb
* Node::JSON::Parser: [matched: true]
  * Node::JSON::Scraper(animals): [matched: true]
    Input : {"animals"=>[{"name"=>"Dog", "emoji"=>"????"}, {"name"=>"Cat", "emoji"=>"????"}]}
    Output: {"Dog"=>"????", "Cat"=>"????"}
#<struct CallableTree::Node::External::Output
 value={"Dog"=>"????", "Cat"=>"????"},
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
    Input : <root><animals><animal emoji='????' name='Dog'/><animal emoji='????' name='Cat'/></animals></root>
    Output: {"Dog"=>"????", "Cat"=>"????"}
#<struct CallableTree::Node::External::Output
 value={"Dog"=>"????", "Cat"=>"????"},
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
    Input : {"fruits"=>[{"name"=>"Red Apple", "emoji"=>"????"}, {"name"=>"Green Apple", "emoji"=>"????"}]}
    Output: {"Red Apple"=>"????", "Green Apple"=>"????"}
#<struct CallableTree::Node::External::Output
 value={"Red Apple"=>"????", "Green Apple"=>"????"},
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
    Input : <root><fruits><fruit emoji='????' name='Red Apple'/><fruit emoji='????' name='Green Apple'/></fruits></root>
    Output: {"Red Apple"=>"????", "Green Apple"=>"????"}
#<struct CallableTree::Node::External::Output
 value={"Red Apple"=>"????", "Green Apple"=>"????"},
 options={:foo=>:bar},
 routes=
  [#<Node::Identity:0x00007ffd8407a740
    @klass=Node::XML::Scraper,
    @type=:fruits>,
   Node::XML::Parser,
   CallableTree::Node::Root]>
---
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jsmmr/ruby_callable_tree.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

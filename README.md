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
  - This `module` is used to define a node that can have child nodes. This node has several strategies (`seekable`, `broadcastable`, `composable`).
- `CallableTree::Node::External`
  - This `module` is used to define a leaf node that cannot have child nodes.
- `CallableTree::Node::Root`
  - This `class` includes `CallableTree::Node::Internal`. When there is no need to customize the internal node, use this `class`.

### Basic

There are two ways to define the nodes: class style and builder style.

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
          .to_h { |element| [element['name'], element['emoji']] }
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
          .to_h { |element| [element['name'], element['emoji']] }
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
{"Dog"=>"🐶", "Cat"=>"🐱"}
---
{"Dog"=>"🐶", "Cat"=>"🐱"}
---
{"Red Apple"=>"🍎", "Green Apple"=>"🍏"}
---
{"Red Apple"=>"🍎", "Green Apple"=>"🍏"}
---
```

##### Builder style

`examples/builder/internal-seekable.rb`:
```ruby
JSONParser =
  CallableTree::Node::Internal::Builder
  .new
  .matcher do |input, **_options|
    File.extname(input) == '.json'
  end
  .caller do |input, **options, &original|
    File.open(input) do |file|
      json = ::JSON.load(file)
      # The following block call is equivalent to calling `super` in the class style.
      original.call(json, **options)
    end
  end
  .terminator { true }
  .build

XMLParser =
  CallableTree::Node::Internal::Builder
  .new
  .matcher do |input, **_options|
    File.extname(input) == '.xml'
  end
  .caller do |input, **options, &original|
    File.open(input) do |file|
      # The following block call is equivalent to calling `super` in the class style.
      original.call(REXML::Document.new(file), **options)
    end
  end
  .terminator { true }
  .build

def build_json_scraper(type)
  CallableTree::Node::External::Builder
    .new
    .matcher do |input, **_options|
      !!input[type.to_s]
    end
    .caller do |input, **_options|
      input[type.to_s]
        .to_h { |element| [element['name'], element['emoji']] }
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
        .to_h { |element| [element['name'], element['emoji']] }
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
{"Dog"=>"🐶", "Cat"=>"🐱"}
---
{"Dog"=>"🐶", "Cat"=>"🐱"}
---
{"Red Apple"=>"🍎", "Green Apple"=>"🍏"}
---
{"Red Apple"=>"🍎", "Green Apple"=>"🍏"}
---
```

#### `CallableTree::Node::Internal#broadcastable`

This strategy broadcasts to output a result of the child nodes as array. It also ignores their `terminate?` methods by default.

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

##### Builder style

`examples/builder/internal-broadcastable.rb`:
```ruby
def less_than(num)
  # The following block call is equivalent to calling `super` in the class style.
  proc { |input, &original| original.call(input) && input < num }
end

LessThan5 =
  CallableTree::Node::Internal::Builder
  .new
  .matcher(&method(:less_than).call(5))
  .build

LessThan10 =
  CallableTree::Node::Internal::Builder
  .new
  .matcher(&method(:less_than).call(10))
  .build

def add(num)
  proc { |input| input + num }
end

Add1 =
  CallableTree::Node::External::Builder
  .new
  .caller(&method(:add).call(1))
  .build

def subtract(num)
  proc { |input| input - num }
end

Subtract1 =
  CallableTree::Node::External::Builder
  .new
  .caller(&method(:subtract).call(1))
  .build

def multiply(num)
  proc { |input| input * num }
end

Multiply2 =
  CallableTree::Node::External::Builder
  .new
  .caller(&method(:multiply).call(2))
  .build

Multiply3 =
  CallableTree::Node::External::Builder
  .new
  .caller(&method(:multiply).call(3))
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

This strategy composes the child nodes to input the output of the previous node into the next node and to output a result.
It also ignores their `terminate?` methods by default.

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

##### Builder style

`examples/builder/internal-composable.rb`:
```ruby
def less_than(num)
  # The following block call is equivalent to calling `super` in the class style.
  proc { |input, &original| original.call(input) && input < num }
end

LessThan5 =
  CallableTree::Node::Internal::Builder
  .new
  .matcher(&method(:less_than).call(5))
  .build

LessThan10 =
  CallableTree::Node::Internal::Builder
  .new
  .matcher(&method(:less_than).call(10))
  .build

def add(num)
  proc { |input| input + num }
end

Add1 =
  CallableTree::Node::External::Builder
  .new
  .caller(&method(:add).call(1))
  .build

def subtract(num)
  proc { |input| input - num }
end

Subtract1 =
  CallableTree::Node::External::Builder
  .new
  .caller(&method(:subtract).call(1))
  .build

def multiply(num)
  proc { |input| input * num }
end

Multiply2 =
  CallableTree::Node::External::Builder
  .new
  .caller(&method(:multiply).call(2))
  .build

Multiply3 =
  CallableTree::Node::External::Builder
  .new
  .caller(&method(:multiply).call(3))
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

`examples/builder/external-verbosify.rb`:
```ruby
...

tree = CallableTree::Node::Root.new.seekable.append(
  JSONParser.new.seekable.append(
    AnimalsJSONScraper.new.verbosify,
    FruitsJSONScraper.new.verbosify
  ),
  XMLParser.new.seekable.append(
    AnimalsXMLScraper.new.verbosify,
    FruitsXMLScraper.new.verbosify
  )
)

...
```

Run `examples/builder/external-verbosify.rb`:
```sh
% ruby examples/class/external-verbosify.rb
#<struct CallableTree::Node::External::Output
  value={"Dog"=>"🐶", "Cat"=>"🐱"},
  options={:foo=>:bar},
  routes=[AnimalsJSONScraper, JSONParser, CallableTree::Node::Root]>
---
#<struct CallableTree::Node::External::Output
  value={"Dog"=>"🐶", "Cat"=>"🐱"},
  options={:foo=>:bar},
  routes=[AnimalsXMLScraper, XMLParser, CallableTree::Node::Root]>
---
#<struct CallableTree::Node::External::Output
  value={"Red Apple"=>"🍎", "Green Apple"=>"🍏"},
  options={:foo=>:bar},
  routes=[FruitsJSONScraper, JSONParser, CallableTree::Node::Root]>
---
#<struct CallableTree::Node::External::Output
  value={"Red Apple"=>"🍎", "Green Apple"=>"🍏"},
  options={:foo=>:bar},
  routes=[FruitsXMLScraper, XMLParser, CallableTree::Node::Root]>
---
```

#### Logging

This is an example of logging.

`examples/builder/logging.rb`:
```ruby
JSONParser =
  CallableTree::Node::Internal::Builder
  .new
  ...
  .hookable
  .build

XMLParser =
  CallableTree::Node::Internal::Builder
  .new
  ...
  .hookable
  .build

def build_json_scraper(type)
  CallableTree::Node::External::Builder
    .new
    ...
    .hookable
    .build
end

...

def build_xml_scraper(type)
  CallableTree::Node::External::Builder
    .new
    ...
    .hookable
    .build
end

...

module Logging
  INDENT_SIZE = 2
  BLANK = ' '
  LIST_STYLE = '*'
  INPUT_LABEL  = 'Input :'
  OUTPUT_LABEL = 'Output:'

  def self.loggable(node)
    node.after_matcher! do |matched, _node_:, **|
      prefix = LIST_STYLE.rjust((_node_.depth * INDENT_SIZE) - INDENT_SIZE + LIST_STYLE.length, BLANK)
      puts "#{prefix} #{_node_.identity}: [matched: #{matched}]"
      matched
    end

    if node.external?
      node
        .before_caller! do |input, *, _node_:, **|
          input_prefix = INPUT_LABEL.rjust((_node_.depth * INDENT_SIZE) + INPUT_LABEL.length, BLANK)
          puts "#{input_prefix} #{input}"
          input
        end
        .after_caller! do |output, _node_:, **|
          output_prefix = OUTPUT_LABEL.rjust((_node_.depth * INDENT_SIZE) + OUTPUT_LABEL.length, BLANK)
          puts "#{output_prefix} #{output}"
          output
        end
    end
  end
end

loggable = Logging.method(:loggable)

tree = CallableTree::Node::Root.new.seekable.append(
  JSONParser.new.tap(&loggable).seekable.append(
    AnimalsJSONScraper.new.tap(&loggable).verbosify,
    FruitsJSONScraper.new.tap(&loggable).verbosify
  ),
  XMLParser.new.tap(&loggable).seekable.append(
    AnimalsXMLScraper.new.tap(&loggable).verbosify,
    FruitsXMLScraper.new.tap(&loggable).verbosify
  )
)

...
```

Also, see `examples/builder/hooks.rb` for detail about `CallableTree::Node::Hooks::*`.

Run `examples/builder/logging.rb`:
```sh
% ruby examples/builder/logging.rb
* JSONParser: [matched: true]
  * AnimalsJSONScraper: [matched: true]
    Input : {"animals"=>[{"name"=>"Dog", "emoji"=>"🐶"}, {"name"=>"Cat", "emoji"=>"🐱"}]}
    Output: {"Dog"=>"🐶", "Cat"=>"🐱"}
#<struct CallableTree::Node::External::Output
 value={"Dog"=>"🐶", "Cat"=>"🐱"},
 options={:foo=>:bar},
 routes=[AnimalsJSONScraper, JSONParser, CallableTree::Node::Root]>
---
* JSONParser: [matched: false]
* XMLParser: [matched: true]
  * AnimalsXMLScraper: [matched: true]
    Input : <root><animals><animal emoji='🐶' name='Dog'/><animal emoji='🐱' name='Cat'/></animals></root>
    Output: {"Dog"=>"🐶", "Cat"=>"🐱"}
#<struct CallableTree::Node::External::Output
 value={"Dog"=>"🐶", "Cat"=>"🐱"},
 options={:foo=>:bar},
 routes=[AnimalsXMLScraper, XMLParser, CallableTree::Node::Root]>
---
* JSONParser: [matched: true]
  * AnimalsJSONScraper: [matched: false]
  * FruitsJSONScraper: [matched: true]
    Input : {"fruits"=>[{"name"=>"Red Apple", "emoji"=>"🍎"}, {"name"=>"Green Apple", "emoji"=>"🍏"}]}
    Output: {"Red Apple"=>"🍎", "Green Apple"=>"🍏"}
#<struct CallableTree::Node::External::Output
 value={"Red Apple"=>"🍎", "Green Apple"=>"🍏"},
 options={:foo=>:bar},
 routes=[FruitsJSONScraper, JSONParser, CallableTree::Node::Root]>
---
* JSONParser: [matched: false]
* XMLParser: [matched: true]
  * AnimalsXMLScraper: [matched: false]
  * FruitsXMLScraper: [matched: true]
    Input : <root><fruits><fruit emoji='🍎' name='Red Apple'/><fruit emoji='🍏' name='Green Apple'/></fruits></root>
    Output: {"Red Apple"=>"🍎", "Green Apple"=>"🍏"}
#<struct CallableTree::Node::External::Output
 value={"Red Apple"=>"🍎", "Green Apple"=>"🍏"},
 options={:foo=>:bar},
 routes=[FruitsXMLScraper, XMLParser, CallableTree::Node::Root]>
```

#### `CallableTree::Node#identity`

If you want to customize the node identity, specify identifier.

`examples/builder/identity.rb`:
```ruby
JSONParser =
  CallableTree::Node::Internal::Builder
  .new
  ...
  .identifier { |_node_:| _node_.object_id }
  .build

XMLParser =
  CallableTree::Node::Internal::Builder
  .new
  ...
  .identifier { |_node_:| _node_.object_id }
  .build

def build_json_scraper(type)
  CallableTree::Node::External::Builder
    .new
    ...
    .identifier { |_node_:| _node_.object_id }
    .build
end

...

def build_xml_scraper(type)
  CallableTree::Node::External::Builder
    .new
    ...
    .identifier { |_node_:| _node_.object_id }
    .build
end

...
```

Run `examples/class/identity.rb`:
```sh
 % ruby examples/builder/identity.rb
#<struct CallableTree::Node::External::Output
  value={"Dog"=>"🐶", "Cat"=>"🐱"},
  options={:foo=>:bar},
  routes=[60, 80, CallableTree::Node::Root]>
---
#<struct CallableTree::Node::External::Output
  value={"Dog"=>"🐶", "Cat"=>"🐱"},
  options={:foo=>:bar},
  routes=[220, 240, CallableTree::Node::Root]>
---
#<struct CallableTree::Node::External::Output
 value={"Red Apple"=>"🍎", "Green Apple"=>"🍏"},
 options={:foo=>:bar},
 routes=[260, 80, CallableTree::Node::Root]>
---
#<struct CallableTree::Node::External::Output
 value={"Red Apple"=>"🍎", "Green Apple"=>"🍏"},
 options={:foo=>:bar},
 routes=[400, 240, CallableTree::Node::Root]>
---
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jsmmr/ruby_callable_tree.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

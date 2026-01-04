## [Unreleased]

- Add Factory style for inline node creation as a third option alongside Class and Builder styles.
  - `CallableTree::Node::External.create` and `CallableTree::Node::Internal.create` factory methods
  - Supports `hookable: true` option for Hooks (before/around/after callbacks)
  - See `examples/factory/*.rb` for details.

## [0.3.11] - 2026-01-03

- Fix a typo in `Strategizable#strategize` where it incorrectly called `strategy!` instead of `strategize!`.`

## [0.3.10] - 2022-12-30

- Change `CallableTree::Node::Internal#broadcastable` to take `matchable` keyword parameter as boolean. It defaults to `true`, which is the same behavior as before.
- Change `CallableTree::Node::Internal#composable` to take `matchable` keyword parameter as boolean. It defaults to `true`, which is the same behavior as before.
- Change `CallableTree::Node::Internal#seekable` to take `matchable` keyword parameter as boolean. It defaults to `true`, which is the same behavior as before.

## [0.3.9] - 2022-11-06

- Change `CallableTree::Node::Internal#broadcastable` to take `terminable` keyword parameter as boolean. It defaults to `false`, which is the same behavior as before.
- Change `CallableTree::Node::Internal#composable` to take `terminable` keyword parameter as boolean. It defaults to `false`, which is the same behavior as before.
- Change `CallableTree::Node::Internal#seekable` to take `terminable` keyword parameter as boolean. It defaults to `true`, which is the same behavior as before.

## [0.3.8] - 2022-05-05

- (Experimental) Add `CallableTree::Node::Internal::Builder#identifier`.
- (Experimental) Add `CallableTree::Node::External::Builder#identifier`.
- (Experimental) Add `CallableTree::Node::Hooks::Terminator`.

## [0.3.7] - 2022-04-09

- Add `CallableTree::Node#internal?`
- Add `CallableTree::Node#external?`
- (Experimental) Change the callables (matcher, caller, terminator) specified in the builder style to receive the current node instance as the `_node_` keyword argument.

## [0.3.6] - 2022-03-29

- (Experimental) Add `CallableTree::Node::Hooks::Matcher`.
  Using this together with `CallableTree::Node::Hooks::Caller` helps to output logs. See `examples/builder/logging.rb` for details.

## [0.3.5] - 2022-03-20

- Add `CallableTree::Node::Internal#seekable?` as an alias for `CallableTree::Node::Internal#seek?`.
- Add `CallableTree::Node::Internal#seekable` as an alias for `CallableTree::Node::Internal#seek`.
- Add `CallableTree::Node::Internal#seekable!` as an alias for `CallableTree::Node::Internal#seek!`.
- Add `CallableTree::Node::Internal#broadcastable?` as an alias for `CallableTree::Node::Internal#broadcast?`.
- Add `CallableTree::Node::Internal#broadcastable` as an alias for `CallableTree::Node::Internal#broadcast`.
- Add `CallableTree::Node::Internal#broadcastable!` as an alias for `CallableTree::Node::Internal#broadcast!`.
- Add `CallableTree::Node::Internal#composable?` as an alias for `CallableTree::Node::Internal#compose?`.
- Add `CallableTree::Node::Internal#composable` as an alias for `CallableTree::Node::Internal#compose`.
- Add `CallableTree::Node::Internal#composable!` as an alias for `CallableTree::Node::Internal#compose!`.
- (Experimental) Add `CallableTree::Node::Internal::Builder#terminator` to use instead of `CallableTree::Node::Internal::Builder#terminater`.
  See `examples/builder/*.rb` for details.

## [0.3.4] - 2022-03-13

- (Experimental) Add `CallableTree::Node::Internal::Builder`.
  See `examples/builder/*.rb` for details.
- (Experimental) Add `CallableTree::Node::External::Builder`.
  See `examples/builder/*.rb` for details.

## [0.3.3] - 2022-02-19

- Add `recursive` option to `CallableTree::Node::Internal#reject` and `CallableTree::Node::Internal#reject!`.
- Add `CallableTree::Node::Internal#find` to return the first node evaluated as `true` by block.

## [0.3.2] - 2022-02-05

- Change `CallableTree::Node::Hooks::Call#before_call` to return a new instance.
  To keep the same behavior as the older version, use `CallableTree::Node::Hooks::Call#before_call!` that makes destructive change.
- Change `CallableTree::Node::Hooks::Call#around_call` to return a new instance.
  To keep the same behavior as the older version, use `CallableTree::Node::Hooks::Call#around_call!` that makes destructive change.
- Change `CallableTree::Node::Hooks::Call#after_call` to return a new instance.
  To keep the same behavior as the older version, use `CallableTree::Node::Hooks::Call#after_call!` that makes destructive change.

## [0.3.1] - 2022-01-10

- Add `CallableTree::Node::Internal#seek?` to check whether the node's strategy is `seek` or not.
- Add `CallableTree::Node::Internal#broadcast?` to check whether the node's strategy is `broadcast` or not.
- Add `CallableTree::Node::Internal#compose?` to check whether the node's strategy is `compose` or not.

## [0.3.0] - 2021-12-27

- Change `CallableTree::Node#match?` to accept inputs to the node as variable length arguments.
- Change `CallableTree::Node#call` to accept inputs to the node as variable length arguments.
- Change `CallableTree::Node#terminate?` to accept inputs to the node as variable length arguments, after the `output` argument.
- Add `CallableTree::Node::Internal#[]` to return the child node using `index`.
- Change `CallableTree::Node::Internal#children` to return a new array including child nodes of the node.
- Add `CallableTree::Node::Internal#children!` to return destructively changeable array including child nodes of the node.

## [0.2.3] - 2021-11-07

- Add `CallableTree::Node::Internal#shake` to recursively execute `CallableTree::Node::Internal#reject`, including child nodes. The child nodes that are empty because their children have been rejected will also be rejected.
- Add `CallableTree::Node::Internal#shake!` that make destructive change.
- Add `CallableTree::Node#outline` that may be useful for writing the specs.

## [0.2.2] - 2021-10-24

- Add `CallableTree::Node::Internal#reject` to return a new node instance without rejected child nodes.
- Add `CallableTree::Node::Internal#reject!` to destructively reject child nodes.

## [0.2.1] - 2021-07-24

- Add `CallableTree::Node#root?`.
- Add `CallableTree::Node::Internal#seek!` that make destructive change.
- Add `CallableTree::Node::Internal#broadcast!` that make destructive change.
- Add `CallableTree::Node::Internal#compose!` that make destructive change.

## [0.2.0] - 2021-06-15

- Change `CallableTree::Node::Internal#append` to return a new instance.
  To keep the same behavior as the older version, use `CallableTree::Node::External#append!` that make destructive change.
- Remove `CallableTree::Node::Internal#<<`. Use `CallableTree::Node::External#append!` instead.
- Change `CallableTree::Node::External#verbosify` to return a new instance.
  To keep the same behavior as the older version, use `CallableTree::Node::External#verbosify!` that make destructive change.

## [0.1.3] - 2021-06-12

- Minor improvements

## [0.1.2] - 2021-05-29

- Add `CallableTree::Node::Internal#compose` (experimental)

## [0.1.1] - 2021-05-27

- Add `CallableTree::Node::Internal#broadcast` (experimental)

## [0.1.0] - 2021-05-19

- Initial release

## [Unreleased]

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

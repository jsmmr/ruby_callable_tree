## [Unreleased]

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

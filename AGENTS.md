# Agent Guide for callable_tree

## Project Overview
`callable_tree` is a Ruby gem that builds a tree of callable nodes. It allows for complex logic flow (like nested `if`/`case`) to be represented as a tree of objects. Nodes are traversed based on matching conditions (`match?`), and executed (`call`).

## Core Concepts
- **Nodes**:
  - `Root`: The entry point of the tree.
  - `Internal`: Branch nodes that contain child nodes. Strategies:
    - `seekable`: Calls the first matching child (like `case`).
    - `broadcastable`: Calls all matching children.
    - `composable`: Pipes output from one child to the next.
  - `External`: Leaf nodes that perform actual work.
- **Traversal**:
  - `match?(input)`: Determines if a node should process the input.
  - `call(input)`: Executes the node logic.
  - `terminate?`: Controls when to stop traversal (mostly for `seekable`).

## Directory Structure
- `lib/`: Source code.
- `spec/`: RSpec tests.
- `examples/`: Usage examples (Class-style and Builder-style).

## Development
- **Tool Version Manager**: mise
- **Language**: Ruby (>= 2.4.0)
- **Dependency Management**: Bundler
  - Execute `bundle` commands via `mise` (e.g., `mise x -- bundle exec ...`)
- **Testing**: RSpec
  - Run all tests: `mise x -- bundle exec rake` or `mise x -- bundle exec rake spec`
- **Commit Messages**: Follow the convention in [CONTRIBUTING.md](CONTRIBUTING.md).
- **Linter/Formatter**:
  - Uses `rubocop`.
  - Run checks: `mise x -- bundle exec rubocop`
- **CI/CD**:
  - GitHub Actions: `.github/workflows/build.yml` runs tests and linter on push/PR.
- **Release Process**:
  - Version: `lib/callable_tree/version.rb`
  - Tagging: Create a git tag (e.g., `v0.4.0`) and push.

## Architecture
- **Composite Pattern**: Used for `Internal` nodes to treat individual objects and compositions uniformly.
- **Builder Pattern**: `CallableTree::Node::Internal::Builder` and `CallableTree::Node::External::Builder` provide a fluent interface for constructing complex trees.


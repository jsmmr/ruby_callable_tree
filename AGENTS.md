# Agent Guide for callable_tree

## Project Overview
`callable_tree` is a Ruby gem for building tree-structured executable workflows. It provides a framework for organizing complex logic into a tree of callable nodes, offering a structured, modular alternative to complex conditional logic. Nodes are matched against input (`match?`) and executed (`call`) in a chain from root to leaf.

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
- **Hooks** (`hookable`):
  - Enable instrumentation (logging, debugging) by adding callbacks.
  - `before_matcher!`, `after_matcher!`: Hook into matching phase.
  - `before_caller!`, `after_caller!`: Hook into call phase.
  - `before_terminator!`, `after_terminator!`: Hook into termination phase.
- **Verbosify** (`verbosify`):
  - Wraps External node output in `CallableTree::Node::External::Output` struct.
  - Provides `value`, `options`, and `routes` (call path) for debugging.

## Directory Structure
- `lib/`: Source code.
- `spec/`: RSpec tests.
- `examples/`: Usage examples.
  - `examples/class/`: Class-style node definitions (using `include CallableTree::Node::*`).
  - `examples/builder/`: Builder-style definitions (using `Builder.new.matcher { }.caller { }.build`).
  - `examples/factory/`: Factory-style definitions (using `External.create(caller: ...)` or `External::Pod.new`).
  - `examples/docs/`: Sample data files (JSON, XML) used by examples.

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
- **Pod Pattern**: `CallableTree::Node::Internal::Pod` and `CallableTree::Node::External::Pod` enable inline node creation via `External.create` / `Internal.create` factory methods with proc-based behaviors.

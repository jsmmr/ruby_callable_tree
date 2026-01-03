# frozen_string_literal: true

module CallableTree
  class Error < StandardError; end
end

require 'forwardable'
require_relative 'callable_tree/version'
require_relative 'callable_tree/node'
require_relative 'callable_tree/node/hooks/matcher'
require_relative 'callable_tree/node/hooks/caller'
require_relative 'callable_tree/node/hooks/terminator'
require_relative 'callable_tree/node/internal/strategy'
require_relative 'callable_tree/node/internal/strategy/broadcast'
require_relative 'callable_tree/node/internal/strategy/seek'
require_relative 'callable_tree/node/internal/strategy/compose'
require_relative 'callable_tree/node/internal/strategizable'
require_relative 'callable_tree/node/external/verbose'
require_relative 'callable_tree/node/external'
require_relative 'callable_tree/node/internal'
require_relative 'callable_tree/node/builder'
require_relative 'callable_tree/node/internal/builder'
require_relative 'callable_tree/node/external/builder'
require_relative 'callable_tree/node/root'

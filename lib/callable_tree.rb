# frozen_string_literal: true

module CallableTree
  class Error < StandardError; end
end

require 'forwardable'
require_relative 'callable_tree/version'
require_relative 'callable_tree/node'
require_relative 'callable_tree/node/hooks/call'
require_relative 'callable_tree/node/internal/broadcast'
require_relative 'callable_tree/node/internal/seek'
require_relative 'callable_tree/node/internal/compose'
require_relative 'callable_tree/node/external/verbose'
require_relative 'callable_tree/node/external'
require_relative 'callable_tree/node/internal'
require_relative 'callable_tree/node/root'

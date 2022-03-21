# frozen_string_literal: true

module CallableTree
  module Node
    class Root
      include Internal
      prepend Hooks::Caller

      def self.inherited(subclass)
        raise ::CallableTree::Error, "#{subclass} cannot inherit #{self}"
      end
    end
  end
end

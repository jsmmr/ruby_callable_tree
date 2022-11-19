# frozen_string_literal: true

module CallableTree
  module Node
    module Internal
      module Strategyable
        def self.included(mod)
          mod.extend ClassMethods
        end

        DEFAUTL_FACTORY = proc do |klass, *_args, matchable:, terminable:, **_kwargs|
          klass.new(matchable: matchable, terminable: terminable)
        end

        @@strategies = {
          seek: {
            klass: Strategy::Seek,
            alias: :seekable,
            matchable: true,
            terminable: true,
            factory: DEFAUTL_FACTORY
          },
          broadcast: {
            klass: Strategy::Broadcast,
            alias: :broadcastable,
            matchable: true,
            terminable: false,
            factory: DEFAUTL_FACTORY
          },
          compose: {
            klass: Strategy::Compose,
            alias: :composable,
            matchable: true,
            terminable: false,
            factory: DEFAUTL_FACTORY
          }
        }

        class << self
          private

          def strategies
            @@strategies
          end

          def define_strategy_methods(_key, config)
            define_method(:"#{config[:alias]}?") { strategy.is_a?(config[:klass]) }

            define_method(config[:alias]) do |*args, matchable: config[:matchable], terminable: config[:terminable], **kwargs|
              if strategy == config[:factory].call(
                config[:klass], *args, matchable: matchable, terminable: terminable, **kwargs
              )
                self
              else
                clone.__send__(:"#{config[:alias]}!", matchable: matchable, terminable: terminable)
              end
            end

            define_method(:"#{config[:alias]}!") do |*args, matchable: config[:matchable], terminable: config[:terminable], **kwargs|
              self.strategy = config[:factory].call(
                config[:klass], *args, matchable: matchable, terminable: terminable, **kwargs
              )
              self
            end
          end
        end

        module ClassMethods
          def store_strategy(key, config)
            raise ::CallableTree::Error, 'Strategy class is required. [:klass]' unless config[:klass]

            key = key.to_sym
            config[:alias] = key unless config[:alias]
            config[:factory] = DEFAUTL_FACTORY unless config[:factory]
            Strategyable.__send__(:strategies)[key] = config
            Strategyable.__send__(:define_strategy_methods, key, config)
          end
        end

        @@strategies.each { |key, config| define_strategy_methods(key, config) }

        # Backward compatibility
        alias seek? seekable?
        alias seek seekable
        alias seek! seekable!
        alias broadcast? broadcastable?
        alias broadcast broadcastable
        alias broadcast! broadcastable!
        alias compose? composable?
        alias compose composable
        alias compose! composable!

        protected

        attr_writer :strategy

        private

        def strategy
          @strategy ||= @@strategies[:seek][:klass].new
        end
      end
    end
  end
end

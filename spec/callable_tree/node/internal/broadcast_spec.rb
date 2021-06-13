# frozen_string_literal: true

RSpec.describe CallableTree::Node::Internal::Broadcast do
  module InternalBroadcastSpec
    class AMatcher
      include CallableTree::Node::Internal

      def match?(input, **)
        super && input < 10
      end

      def call(input, **options)
        super(format('%03d', input), **options)
      end
    end

    class BMatcher
      include CallableTree::Node::Internal

      def match?(input, **)
        super && input < 20
      end

      def call(input, **options)
        super(format('%04d', input), **options)
      end
    end
  end

  describe '#call' do
    subject { described_class.new.call(nodes, input: input, options: options) }

    let(:nodes) do
      [
        InternalSeekSpec::AMatcher.new.append(leaf),
        InternalSeekSpec::BMatcher.new.append(leaf)
      ]
    end

    let(:leaf) do
      ->(input, prefix:, suffix:) { "#{prefix}#{input}#{suffix}" }
    end

    context 'input: less than 10' do
      let(:input) { 9 }
      let(:options) { { prefix: '(', suffix: ')' } }
      it { is_expected.to eq ['(009)', '(0009)'] }
    end

    context 'input: less than 20' do
      let(:input) { 13 }
      let(:options) { { prefix: '[', suffix: ']' } }
      it { is_expected.to eq [nil, '[0013]'] }
    end
  end
end

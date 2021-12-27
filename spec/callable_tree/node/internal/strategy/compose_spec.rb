# frozen_string_literal: true

RSpec.describe CallableTree::Node::Internal::Strategy::Compose do
  describe '#call' do
    subject { described_class.new.call(nodes, *inputs, **options) }

    let(:nodes) do
      [
        LessThan.new(10).append(proc { |input| input * 2 }),
        LessThan.new(20).append(proc { |*inputs, **| inputs.sum * 3 }),
        CallableTree::Node::External.proxify(
          ->(input, *, prefix:, suffix:) { "#{prefix}#{input}#{suffix}" }
        )
      ]
    end

    context 'input: less than 10' do
      let(:inputs) { [9, 1] }
      let(:options) { { prefix: '(', suffix: ')' } }
      it { is_expected.to eq '(57)' }
    end

    context 'input: greater than 10' do
      let(:inputs) { [13, 4, 1] }
      let(:options) { { prefix: '[', suffix: ']' } }
      it { is_expected.to eq '[54]' }
    end
  end
end

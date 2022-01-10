# frozen_string_literal: true

RSpec.describe CallableTree::Node::Internal::Strategy::Compose do
  describe '#name' do
    subject { described_class.new.name }
    it { is_expected.to eq :compose }
  end

  describe '#==' do
    subject { described_class.new }

    context 'when strategies are the same' do
      it { is_expected.to eq described_class.new }
    end

    context 'when strategies are not the same' do
      let(:other) do
        [
          CallableTree::Node::Internal::Strategy::Broadcast,
          CallableTree::Node::Internal::Strategy::Seek
        ].sample
      end
      it { is_expected.not_to eq other.new }
    end
  end

  describe '#eql?' do
    subject { described_class.new }

    context 'when strategies are the same' do
      it { is_expected.to eql described_class.new }
    end

    context 'when strategies are not the same' do
      let(:other) do
        [
          CallableTree::Node::Internal::Strategy::Broadcast,
          CallableTree::Node::Internal::Strategy::Seek
        ].sample
      end
      it { is_expected.not_to eql other.new }
    end
  end

  describe '#hash' do
    subject { described_class.new.hash }

    context 'when strategies are the same' do
      it { is_expected.to eq described_class.new.hash }
    end

    context 'when strategies are not the same' do
      let(:other) do
        [
          CallableTree::Node::Internal::Strategy::Broadcast,
          CallableTree::Node::Internal::Strategy::Seek
        ].sample
      end
      it { is_expected.not_to eq other.new.hash }
    end
  end

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

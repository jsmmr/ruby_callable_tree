# frozen_string_literal: true

RSpec.describe CallableTree::Node::Internal::Strategy::Compose do
  describe '#name' do
    subject { described_class.new.name }
    it { is_expected.to eq :compose }
  end

  describe '#==' do
    subject { described_class.new(matchable: matchable, terminable: terminable) }

    let(:matchable) { [true, false].sample }
    let(:terminable) { [true, false].sample }

    context 'when strategies are the same' do
      context 'when options are the same' do
        it { is_expected.to eq described_class.new(matchable: matchable, terminable: terminable) }
      end

      context 'when options are not the same' do
        it { is_expected.not_to eq described_class.new(matchable: !matchable, terminable: terminable) }
        it { is_expected.not_to eq described_class.new(matchable: matchable, terminable: !terminable) }
      end
    end

    context 'when strategies are not the same' do
      let(:other) do
        [
          CallableTree::Node::Internal::Strategy::Broadcast,
          CallableTree::Node::Internal::Strategy::Seek
        ].sample
      end
      it { is_expected.not_to eq other.new(matchable: matchable, terminable: terminable) }
    end
  end

  describe '#eql?' do
    subject { described_class.new(matchable: matchable, terminable: terminable) }

    let(:matchable) { [true, false].sample }
    let(:terminable) { [true, false].sample }

    context 'when strategies are the same' do
      context 'when options are the same' do
        it { is_expected.to eql described_class.new(matchable: matchable, terminable: terminable) }
      end

      context 'when options are not the same' do
        it { is_expected.not_to eq described_class.new(matchable: !matchable, terminable: terminable) }
        it { is_expected.not_to eq described_class.new(matchable: matchable, terminable: !terminable) }
      end
    end

    context 'when strategies are not the same' do
      let(:other) do
        [
          CallableTree::Node::Internal::Strategy::Broadcast,
          CallableTree::Node::Internal::Strategy::Seek
        ].sample
      end
      it { is_expected.not_to eql other.new(matchable: matchable, terminable: terminable) }
    end
  end

  describe '#hash' do
    subject { described_class.new(matchable: matchable, terminable: terminable).hash }

    let(:matchable) { [true, false].sample }
    let(:terminable) { [true, false].sample }

    context 'when strategies are the same' do
      context 'when options are the same' do
        it { is_expected.to eq described_class.new(matchable: matchable, terminable: terminable).hash }
      end

      context 'when options are not the same' do
        it { is_expected.not_to eq described_class.new(matchable: !matchable, terminable: terminable).hash }
        it { is_expected.not_to eq described_class.new(matchable: matchable, terminable: !terminable).hash }
      end
    end

    context 'when strategies are not the same' do
      let(:other) do
        [
          CallableTree::Node::Internal::Strategy::Broadcast,
          CallableTree::Node::Internal::Strategy::Seek
        ].sample
      end
      it { is_expected.not_to eq other.new(matchable: matchable, terminable: terminable).hash }
    end
  end

  describe '#matchable?' do
    subject { described_class.new(matchable: matchable).matchable? }

    context 'matchable: true' do
      let(:matchable) { true }
      it { is_expected.to be true }
    end

    context 'matchable: false' do
      let(:matchable) { false }
      it { is_expected.to be false }
    end
  end

  describe '#terminable?' do
    subject { described_class.new(terminable: terminable).terminable? }

    context 'terminable: true' do
      let(:terminable) { true }
      it { is_expected.to be true }
    end

    context 'terminable: false' do
      let(:terminable) { false }
      it { is_expected.to be false }
    end
  end

  describe '#call' do
    subject do
      described_class.new(matchable: matchable, terminable: terminable).call(tree.children, *inputs, **options)
    end

    let(:tree) do
      CallableTree::Node::Root.new.composable.append(
        build_less_than(10).new.append(proc { |input| input * 2 }),
        build_less_than(20).new.append(proc { |*inputs, **| inputs.sum * 3 }),
        ->(input, *, prefix:, suffix:, **) { "#{prefix}#{input}#{suffix}" }
      )
    end

    let(:matchable) { true }
    let(:terminable) { false }

    context 'matchable: true' do
      let(:matchable) { true }

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

    context 'matchable: false' do
      let(:matchable) { false }

      context 'input: less than 10' do
        let(:inputs) { [9, 1] }
        let(:options) { { prefix: '(', suffix: ')' } }
        it { is_expected.to eq 9 }
      end

      context 'input: greater than 10' do
        let(:inputs) { [13, 4, 1] }
        let(:options) { { prefix: '[', suffix: ']' } }
        it { is_expected.to eq 13 }
      end
    end

    context 'terminable: true' do
      let(:terminable) { true }

      context 'input: less than 10' do
        let(:inputs) { [9, 1] }
        let(:options) { { prefix: '(', suffix: ')' } }
        it { is_expected.to eq 18 }
      end

      context 'input: greater than 10' do
        let(:inputs) { [13, 4, 1] }
        let(:options) { { prefix: '[', suffix: ']' } }
        it { is_expected.to eq 54 }
      end
    end

    context 'terminable: false' do
      let(:terminable) { false }

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
end

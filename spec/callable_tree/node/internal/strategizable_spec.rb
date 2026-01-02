# frozen_string_literal: true

RSpec.describe CallableTree::Node::Internal::Strategizable do
  Internal = CallableTree::Node::Internal

  describe '.store_strategy' do
    subject { Internal::Builder.new.build.new }

    before { Internal.store_strategy(key, config) }

    let(:key) { :test }
    let(:config) do
      {
        klass: Class.new do
          include Internal::Strategy

          def initialize(matchable:, terminable:)
            self.matchable = matchable
            self.terminable = terminable
          end

          def name
            :test
          end

          def call(_nodes, input, *, **)
            format(input, matchable?, terminable?)
          end
        end,
        alias: :testable,
        matchable: [true, false].sample,
        terminable: [true, false].sample,
        factory: proc do |klass, *, matchable:, terminable:, **|
          klass.new(matchable: matchable, terminable: terminable)
        end
      }
    end

    it { is_expected.to respond_to(:testable?) }
    it { is_expected.to respond_to(:testable) }
    it { is_expected.to respond_to(:testable!) }
    it {
      expect(subject.testable.call('matcher: %s, terminator: %s')).to eq("matcher: #{config[:matchable]}, terminator: #{config[:terminable]}")
    }
  end

  describe '#seek?' do
    subject { node.seek? }

    let(:node) { Class.new { include Internal }.new }

    context 'when strategy is `seek`' do
      before { node.send(:strategy=, Internal::Strategy::Seek.new) }
      it { is_expected.to be true }
    end

    context 'when strategy is not `seek`' do
      before do
        node.send(:strategy=, [
          Internal::Strategy::Broadcast.new,
          Internal::Strategy::Compose.new
        ].sample)
      end
      it { is_expected.to be false }
    end
  end

  describe '#seek' do
    subject { node.seek(**options) }

    let(:node) { Class.new { include Internal }.new }
    let(:options) { { matchable: [true, false].sample, terminable: [true, false].sample } }

    context 'when current strategy is `seek`' do
      before { node.send(:strategy=, Internal::Strategy::Seek.new(**current_options)) }

      context 'when options are the same' do
        let(:current_options) { options }

        it { is_expected.to be node }
        it { expect(subject.send(:strategy)).to be_a Internal::Strategy::Seek }
      end

      context 'when options are not the same' do
        let(:current_options) do
          [
            { matchable: !options[:matchable], terminable: options[:terminable] },
            { matchable: options[:matchable], terminable: !options[:terminable] },
            { matchable: !options[:matchable], terminable: !options[:terminable] }
          ].sample
        end

        it { is_expected.not_to be node }
        it { expect(subject.send(:strategy)).to be_a Internal::Strategy::Seek }
      end
    end

    context 'when current strategy is `broadcast`' do
      before { node.send(:strategy=, Internal::Strategy::Broadcast.new(**options)) }

      it { is_expected.not_to be node }
      it { expect(subject.send(:strategy)).to be_a Internal::Strategy::Seek }
    end

    context 'when current strategy is `compose`' do
      before { node.send(:strategy=, Internal::Strategy::Compose.new(**options)) }

      it { is_expected.not_to be node }
      it { expect(subject.send(:strategy)).to be_a Internal::Strategy::Seek }
    end
  end

  describe '#seek!' do
    subject { node.seek!(**options) }

    let(:node) { Class.new { include Internal }.new }
    let(:options) { { matchable: [true, false].sample, terminable: [true, false].sample } }

    context 'when current strategy is `seek`' do
      before { node.send(:strategy=, Internal::Strategy::Seek.new(**options)) }

      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a Internal::Strategy::Seek }
    end

    context 'when current strategy is `broadcast`' do
      before { node.send(:strategy=, Internal::Strategy::Broadcast.new(**options)) }

      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a Internal::Strategy::Seek }
    end

    context 'when current strategy is `compose`' do
      before { node.send(:strategy=, Internal::Strategy::Compose.new(**options)) }

      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a Internal::Strategy::Seek }
    end
  end

  describe '#broadcast?' do
    subject { node.broadcast? }

    let(:node) { Class.new { include Internal }.new }

    context 'when strategy is `broadcast`' do
      before { node.send(:strategy=, Internal::Strategy::Broadcast.new) }
      it { is_expected.to be true }
    end

    context 'when strategy is not `broadcast`' do
      before do
        node.send(:strategy=, [
          Internal::Strategy::Seek.new,
          Internal::Strategy::Compose.new
        ].sample)
      end
      it { is_expected.to be false }
    end
  end

  describe '#broadcast' do
    subject { node.broadcast(**options) }

    let(:node) { Class.new { include Internal }.new }
    let(:options) { { matchable: [true, false].sample, terminable: [true, false].sample } }

    context 'when current strategy is `seek`' do
      before { node.send(:strategy=, Internal::Strategy::Seek.new(**options)) }

      it { is_expected.not_to be node }
      it { expect(subject.send(:strategy)).to be_a Internal::Strategy::Broadcast }
    end

    context 'when current strategy is `broadcast`' do
      before { node.send(:strategy=, Internal::Strategy::Broadcast.new(**current_options)) }

      context 'when options are the same' do
        let(:current_options) { options }

        it { is_expected.to be node }
        it { expect(subject.send(:strategy)).to be_a Internal::Strategy::Broadcast }
      end

      context 'when options are not the same' do
        let(:current_options) do
          [
            { matchable: !options[:matchable], terminable: options[:terminable] },
            { matchable: options[:matchable], terminable: !options[:terminable] },
            { matchable: !options[:matchable], terminable: !options[:terminable] }
          ].sample
        end

        it { is_expected.not_to be node }
        it { expect(subject.send(:strategy)).to be_a Internal::Strategy::Broadcast }
      end
    end

    context 'when current strategy is `compose`' do
      before { node.send(:strategy=, Internal::Strategy::Compose.new(**options)) }

      it { is_expected.not_to be node }
      it { expect(subject.send(:strategy)).to be_a Internal::Strategy::Broadcast }
    end
  end

  describe '#broadcast!' do
    subject { node.broadcast!(**options) }

    let(:node) { Class.new { include Internal }.new }
    let(:options) { { matchable: [true, false].sample, terminable: [true, false].sample } }

    context 'when current strategy is `seek`' do
      before { node.send(:strategy=, Internal::Strategy::Seek.new(**options)) }

      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a Internal::Strategy::Broadcast }
    end

    context 'when current strategy is `broadcast`' do
      before { node.send(:strategy=, Internal::Strategy::Broadcast.new(**options)) }

      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a Internal::Strategy::Broadcast }
    end

    context 'when current strategy is `compose`' do
      before { node.send(:strategy=, Internal::Strategy::Compose.new(**options)) }

      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a Internal::Strategy::Broadcast }
    end
  end

  describe '#compose?' do
    subject { node.compose? }

    let(:node) { Class.new { include Internal }.new }

    context 'when strategy is `compose`' do
      before { node.send(:strategy=, Internal::Strategy::Compose.new) }
      it { is_expected.to be true }
    end

    context 'when strategy is not `compose`' do
      before do
        node.send(:strategy=, [
          Internal::Strategy::Seek.new,
          Internal::Strategy::Broadcast.new
        ].sample)
      end
      it { is_expected.to be false }
    end
  end

  describe '#compose' do
    subject { node.compose(**options) }

    let(:node) { Class.new { include Internal }.new }
    let(:options) { { matchable: [true, false].sample, terminable: [true, false].sample } }

    context 'when current strategy is `seek`' do
      before { node.send(:strategy=, Internal::Strategy::Seek.new(**options)) }

      it { is_expected.not_to be node }
      it { expect(subject.send(:strategy)).to be_a Internal::Strategy::Compose }
    end

    context 'when current strategy is `broadcast`' do
      before { node.send(:strategy=, Internal::Strategy::Broadcast.new(**options)) }

      it { is_expected.not_to be node }
      it { expect(subject.send(:strategy)).to be_a Internal::Strategy::Compose }
    end

    context 'when current strategy is `compose`' do
      before { node.send(:strategy=, Internal::Strategy::Compose.new(**current_options)) }

      context 'when options are the same' do
        let(:current_options) { options }

        it { is_expected.to be node }
        it { expect(subject.send(:strategy)).to be_a Internal::Strategy::Compose }
      end

      context 'when options are not the same' do
        let(:current_options) do
          [
            { matchable: !options[:matchable], terminable: options[:terminable] },
            { matchable: options[:matchable], terminable: !options[:terminable] },
            { matchable: !options[:matchable], terminable: !options[:terminable] }
          ].sample
        end

        it { is_expected.not_to be node }
        it { expect(subject.send(:strategy)).to be_a Internal::Strategy::Compose }
      end
    end
  end

  describe '#compose!' do
    subject { node.compose!(**options) }

    let(:node) { Class.new { include Internal }.new }
    let(:options) { { matchable: [true, false].sample, terminable: [true, false].sample } }

    context 'when current strategy is `seek`' do
      before { node.send(:strategy=, Internal::Strategy::Seek.new(**options)) }

      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a Internal::Strategy::Compose }
    end

    context 'when current strategy is `broadcast`' do
      before { node.send(:strategy=, Internal::Strategy::Broadcast.new(**options)) }

      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a Internal::Strategy::Compose }
    end

    context 'when current strategy is `compose`' do
      before { node.send(:strategy=, Internal::Strategy::Compose.new(**options)) }

      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a Internal::Strategy::Compose }
    end
  end
end

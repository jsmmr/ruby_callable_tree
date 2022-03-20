# frozen_string_literal: true

RSpec.describe CallableTree::Node::Internal::Builder do
  describe '#build' do
    let(:matcher) do
      proc { |*inputs, **options, &block| block.call(*inputs, **options) && matched }
    end

    let(:caller) do
      proc { |*inputs, **options, &block| block.call(*inputs, **options) }
    end

    let(:terminator) do
      proc { |output, *inputs, **options, &block| block.call(output, *inputs, **options) && terminated }
    end

    let(:builder) do
      described_class
        .new
        .matcher(&matcher)
        .caller(&caller)
        .tap do |node_class|
          if [true, false].sample
            node_class.terminator(&terminator)
          else
            node_class.terminater(&terminator)
          end
        end
    end

    let(:node) { builder.build.new }

    context '#new' do
      subject { node }
      it { is_expected.to be_a ::CallableTree::Node::Internal }

      context '#match?' do
        subject { node.match?(*inputs, **options) }

        before do
          expect(matcher).to receive(:call).once.with(*inputs, **options).and_call_original
        end

        let(:inputs) { [1, 2] }
        let(:options) { { a: 1, b: 2 } }

        context 'when node has child' do
          before do
            node.append!(proc { 'child' })
          end

          context 'matched: true' do
            let(:matched) { true }
            it { is_expected.to be true }
          end

          context 'matched: false' do
            let(:matched) { false }
            it { is_expected.to be false }
          end
        end

        context 'when node has no child' do
          context 'matched: true' do
            let(:matched) { [true, false].sample }
            it { is_expected.to be false }
          end
        end
      end

      context '#call' do
        subject { node.call(*inputs, **options) }

        before do
          node.append!(proc { 'child' })
        end

        before do
          expect(caller).to receive(:call).once.with(*inputs, **options).and_call_original
        end

        let(:inputs) { [1, 2] }
        let(:options) { { a: 1, b: 2 } }

        it { is_expected.to eq 'child' }
      end

      context '#terminate?' do
        subject { node.terminate?(output, *inputs, **options) }

        before do
          node.append!(proc { 'child' })
        end

        before do
          expect(terminator).to receive(:call).once.with(output, *inputs, **options).and_call_original
        end

        let(:output) { :output }
        let(:inputs) { [1, 2] }
        let(:options) { { a: 1, b: 2 } }

        context 'terminated: true' do
          let(:terminated) { true }
          it { is_expected.to be true }
        end

        context 'terminated: false' do
          let(:terminated) { false }
          it { is_expected.to be false }
        end
      end
    end
  end
end

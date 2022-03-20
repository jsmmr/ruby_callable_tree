# frozen_string_literal: true

RSpec.describe CallableTree::Node::External::Builder do
  describe '#build' do
    let(:matcher) do
      proc { |input, *, **| input < 10 }
    end

    let(:caller) do
      proc { |input, *, **| input * 2 }
    end

    let(:terminator) do
      proc { |output, *, **| output > 10 }
    end

    let(:builder) do
      described_class
        .new
        .matcher(&matcher)
        .caller(&caller)
        .terminator(&terminator)
    end

    let(:node) { builder.build.new }

    context '#new' do
      subject { node }
      it { is_expected.to be_a ::CallableTree::Node::External }

      context '#match?' do
        subject { node.match?(*inputs) }

        context 'input: 9' do
          let(:inputs) { [9] }
          it { is_expected.to be true }
        end

        context 'input: 10' do
          let(:inputs) { [10] }
          it { is_expected.to be false }
        end
      end

      context '#call' do
        subject { node.call(*inputs) }

        context 'input: 9' do
          let(:inputs) { [9] }
          it { is_expected.to eq 18 }
        end

        context 'input: 10' do
          let(:inputs) { [10] }
          it { is_expected.to eq 20 }
        end
      end

      context '#terminate?' do
        subject { node.terminate?(output) }

        context 'input: 10' do
          let(:output) { 10 }
          it { is_expected.to be false }
        end

        context 'input: 11' do
          let(:output) { 11 }
          it { is_expected.to be true }
        end
      end
    end
  end
end

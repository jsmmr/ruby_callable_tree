# frozen_string_literal: true

RSpec.describe CallableTree::Node::External::Pod do
  describe 'Constructor style' do
    let(:node) do
      described_class.new(
        matcher: ->(input, **) { input < 10 },
        caller: ->(input, **) { input * 2 },
        terminator: ->(output, *, **) { output > 10 }
      )
    end

    it { expect(node).to be_a CallableTree::Node::External }
    it { expect(node.match?(5)).to be true }
    it { expect(node.match?(15)).to be false }
    it { expect(node.call(5)).to eq 10 }
    it { expect(node.terminate?(11)).to be true }
    it { expect(node.terminate?(9)).to be false }
  end

  describe 'Block style' do
    let(:node) do
      described_class.new do |node|
        node.matcher { |input, **| input < 10 }
        node.caller { |input, **| input * 2 }
        node.terminator { |output, *, **| output > 10 }
      end
    end

    it { expect(node).to be_a CallableTree::Node::External }
    it { expect(node.match?(5)).to be true }
    it { expect(node.call(5)).to eq 10 }
    it { expect(node.terminate?(11)).to be true }
  end

  describe 'without caller' do
    let(:node) { described_class.new }

    it 'raises error on call' do
      expect { node.call(1) }.to raise_error(CallableTree::Error, 'caller is not set')
    end
  end
end

RSpec.describe 'CallableTree::Node::External.create' do
  describe 'Factory style' do
    let(:node) do
      CallableTree::Node::External.create(
        matcher: ->(input, **) { input < 10 },
        caller: ->(input, **) { input * 2 }
      )
    end

    it { expect(node).to be_a CallableTree::Node::External::Pod }
    it { expect(node.match?(5)).to be true }
    it { expect(node.call(5)).to eq 10 }
  end

  describe 'Factory + Block style' do
    let(:node) do
      CallableTree::Node::External.create do |node|
        node.caller { |input, **| input * 3 }
      end
    end

    it { expect(node.call(5)).to eq 15 }
  end

  describe 'hookable: true' do
    let(:node) do
      CallableTree::Node::External.create(hookable: true) do |node|
        node.caller { |input, **| input * 2 }
      end
    end

    it { expect(node).to be_a CallableTree::Node::External::HookablePod }
    it { expect(node).to respond_to(:before_call) }
    it { expect(node).to respond_to(:around_call) }
    it { expect(node).to respond_to(:after_call) }
  end
end

RSpec.describe CallableTree::Node::Internal::Pod do
  describe 'Constructor style' do
    let(:node) do
      described_class.new(
        matcher: ->(*_args, _node_:, **_opts, &block) { block.call && true }
      ).tap { |n| n.append!(proc { 'child' }) }
    end

    it { expect(node).to be_a CallableTree::Node::Internal }
    it { expect(node.match?(1)).to be true }
    it { expect(node.call(1)).to eq 'child' }
  end

  describe 'Block style' do
    let(:node) do
      described_class.new do |node|
        node.identifier { 'my-internal-pod' }
      end
    end

    it { expect(node.identity).to eq 'my-internal-pod' }
  end
end

RSpec.describe 'CallableTree::Node::Internal.create' do
  describe 'Factory style' do
    let(:node) do
      CallableTree::Node::Internal.create do |node|
        node.identifier { 'factory-pod' }
      end
    end

    it { expect(node).to be_a CallableTree::Node::Internal::Pod }
    it { expect(node.identity).to eq 'factory-pod' }
  end

  describe 'hookable: true' do
    let(:node) do
      CallableTree::Node::Internal.create(hookable: true)
    end

    it { expect(node).to be_a CallableTree::Node::Internal::HookablePod }
    it { expect(node).to respond_to(:before_matcher) }
  end
end

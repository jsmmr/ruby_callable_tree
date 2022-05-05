# frozen_string_literal: true

require_relative 'lib/callable_tree/version'

Gem::Specification.new do |spec|
  spec.name          = 'callable_tree'
  spec.version       = CallableTree::VERSION
  spec.authors       = ['jsmmr']
  spec.email         = ['jsmmr@icloud.com']

  spec.summary       = 'Builds a tree by linking callable nodes. The nodes that match the conditions are called in a chain from the root node to the leaf node. These are like nested `if` or `case` expressions.'
  spec.description   = 'Builds a tree by linking callable nodes. The nodes that match the conditions are called in a chain from the root node to the leaf node. These are like nested `if` or `case` expressions.'
  spec.homepage      = 'https://github.com/jsmmr/ruby_callable_tree'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.4.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/jsmmr/ruby_callable_tree'
  spec.metadata['changelog_uri'] = "https://github.com/jsmmr/ruby_callable_tree/blob/v#{spec.version}/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata['rubygems_mfa_required'] = 'true'
end

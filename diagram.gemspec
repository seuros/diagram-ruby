# frozen_string_literal: true

require_relative 'lib/diagrams/version'

Gem::Specification.new do |spec|
  spec.name = 'diagram'
  spec.version = Diagrams::VERSION
  spec.authors = ['Abdelkader Boudih']
  spec.email = ['seuros@pre-history.com']

  spec.summary = 'Work with diagrams in Ruby'
  spec.description = spec.summary
  spec.homepage = 'https://github.com/seuros/diagram-ruby'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.3.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = 'https://github.com/seuros/diagram-ruby/blob/master/CHANGELOG.md'

  # Use Dir.glob to list all files within the lib and sig directories
  spec.files = Dir.glob('{lib,sig}/**/*')
  spec.require_paths = ['lib']
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.add_dependency 'dry-equalizer', '>= 0.2'
  spec.add_dependency 'dry-struct', '>= 1.6.0'
  spec.add_dependency 'dry-types', '>= 1.0'
  spec.add_dependency 'json'
  spec.add_dependency 'zeitwerk', '>= 2.6'

  # Development Dependencies
  spec.add_development_dependency 'bundler', '>= 2.5.5'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rubocop', '~> 1.59'
  spec.add_development_dependency 'rubocop-minitest', '~> 0.34'
  spec.add_development_dependency 'rubocop-performance', '~> 1.20'
  spec.add_development_dependency 'rubocop-rake', '~> 0.6'
  spec.add_development_dependency 'steep'
  spec.add_development_dependency 'yard', '~> 0.9'
end

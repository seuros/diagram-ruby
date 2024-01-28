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
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = 'https://github.com/seuros/diagram-ruby/blob/master/CHANGELOG.md'

  spec.files = Dir.glob('lib/**/*', File::FNM_DOTMATCH)
  spec.require_paths = ['lib']
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.add_dependency 'dry-struct', '>= 1.6.0'
end

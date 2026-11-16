# frozen_string_literal: true

require 'digest'
require 'json'
require 'zeitwerk'
require_relative 'diagrams/version'

loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/diagram.rb")
loader.inflector.inflect(
  'er_diagram' => 'ERDiagram',
  'erd_entity' => 'ERDEntity',
  'erd_attribute' => 'ERDAttribute',
  'erd_relationship' => 'ERDRelationship'
)
loader.setup
# Diagrams::Base.from_h finds diagram types among the loaded subclasses.
loader.eager_load

# Diagrams as data: build them with add_* methods, compare, diff and
# serialize them. Renderers (the mermaid gem) turn them into text.
module Diagrams
end

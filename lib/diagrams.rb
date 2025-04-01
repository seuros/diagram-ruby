# frozen_string_literal: true

require 'zeitwerk'
require 'digest'
require 'json'
require 'dry-equalizer'
require 'dry-struct'
require_relative 'diagrams/version'

loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/diagram.rb")
# Add inflection for ERDiagram
loader.inflector.inflect(
  'er_diagram' => 'ERDiagram',
  'erd_entity' => 'ERDEntity',
  'erd_attribute' => 'ERDAttribute',
  'erd_relationship' => 'ERDRelationship'
)
loader.setup

# This module handles diagrams creation and manipulation.
module Diagrams
end

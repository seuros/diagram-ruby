# frozen_string_literal: true

require 'zeitwerk'
require 'digest'
require 'json'
require 'dry-equalizer'
require 'dry-struct'
require_relative 'diagrams/version'

loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/diagram.rb")
loader.setup

# This module handles diagrams creation and manipulation.
module Diagrams
end

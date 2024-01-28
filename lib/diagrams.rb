# frozen_string_literal: true

require_relative 'diagrams/version'
require 'dry-struct'

loader = Zeitwerk::Loader.for_gem
loader.setup

module Diagrams
end

# frozen_string_literal: true

require 'zeitwerk'
require_relative 'diagrams/version' # Keep this for gemspec access before setup

loader = Zeitwerk::Loader.for_gem
loader.setup

# This module handles diagrams creation and manipulation.
module Diagrams
end

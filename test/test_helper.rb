# frozen_string_literal: true

require 'diagram'

require 'minitest/autorun'

class DiagramTest < Minitest::Test
  def subject
    Object.const_get(self.class.name.gsub(/Test$/, ''))
  end

  def test_class_methods
    skip if instance_of?(DiagramTest)

    assert_respond_to subject, :from_json
  end

  def deep_stringify_keys(hash)
    hash.each_with_object({}) do |(key, value), new_hash|
      new_hash[key.to_s] = value.is_a?(Hash) ? deep_stringify_keys(value) : value
    end
  end
end

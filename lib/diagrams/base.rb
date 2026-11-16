# frozen_string_literal: true

module Diagrams
  # A diagram is a title plus ordered collections of elements. Subclasses
  # declare their collections and the add_* method that fills each one; every
  # element, including those loaded by .from_h, goes through that method, so
  # it passes the same checks. Collections are frozen arrays of immutable
  # elements. Diagrams compare by type and content.
  class Base
    attr_reader :title, :version

    class << self
      # The serialized type name: "flowchart_diagram", "er_diagram", ...
      def type = name.split('::').last.gsub(/(?<=[a-z\d])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])/, '_').downcase

      # Collection name => the add_* method that appends to it, in order.
      def collections = @collections ||= {}

      # Rebuilds a diagram from #to_h output, with string or symbol keys.
      # Diagrams::Base.from_h accepts any type; a subclass only its own. A
      # container or key of the wrong class raises TypeError.
      def from_h(hash)
        hash = Check.symbolize(Check.record(hash, :diagram))
        klass = diagram_class(hash[:type])
        return klass.from_h(hash) unless klass.equal?(self)

        data = Check.record(hash.fetch(:data) { raise ArgumentError, 'diagram hash has no :data' }, :data)
        diagram = restore(data, version: hash.fetch(:version, 1))
        return diagram if hash[:checksum].nil? || hash[:checksum] == diagram.checksum

        raise ArgumentError, "checksum mismatch: expected #{hash[:checksum]}, content has #{diagram.checksum}"
      end

      def from_json(json) = from_h(JSON.parse(json))

      # Marshal loads through from_json, so a loaded diagram passes the checks.
      def _load(json) = from_json(json)

      private

      # Settings through the constructor, then each element through its add_* method.
      def restore(data, version:)
        new(version:, **data.except(*collections.keys)).tap do |diagram|
          collections.each do |name, add|
            Check.list(data.fetch(name, []), name).each { diagram.public_send(add, **Check.record(it, name)) }
          end
        end
      end

      def collection(name, add: nil)
        collections[name] = add
        define_method(name) { @elements.fetch(name) }
      end

      def diagram_class(type)
        klass = equal?(Base) ? Base.subclasses.find { it.type == type } : self
        return klass if klass&.type == type

        raise ArgumentError, "not a #{equal?(Base) ? 'known' : self.type} diagram type: #{type.inspect}"
      end
    end

    def initialize(title: nil, version: 1)
      raise NotImplementedError, "#{self.class} is abstract" if instance_of?(Base)

      @title = Check.optional_string(title, :title)
      @version = version
      @elements = self.class.collections.keys.to_h { [it, [].freeze] }
    end

    # Content as plain data: settings, then each collection.
    def content = settings.merge(@elements.transform_values { |list| list.map(&:to_h) }).compact

    def checksum = Digest::SHA256.hexdigest(JSON.generate(content))

    def to_h = { type: self.class.type, version:, checksum:, data: content }

    def to_json(*) = JSON.generate(to_h, *)

    def _dump(_level) = to_json

    # Strict: content compares with eql?, so 1 and 1.0 differ, as they do in
    # the JSON and the checksum, and equal diagrams hash equally.
    def ==(other) = other.instance_of?(self.class) && other.content.eql?(content)
    alias eql? ==

    def hash = [self.class, content].hash

    # Per collection, the elements added, removed and modified in +other+.
    # Keyed elements match by Element#key; elements without a key match by
    # value and count, so each extra copy of an edge shows up once. Collections
    # without changes are left out.
    def diff(other)
      raise TypeError, "cannot diff #{self.class} with #{other.class}" unless other.instance_of?(self.class)

      @elements.to_h { |name, mine| [name, diff_collection(mine, other.public_send(name))] }.reject { _2.empty? }
    end

    private

    # Settings serialized ahead of the collections; subclasses extend this.
    def settings = { title: }

    def append(name, element)
      if element.keyed? && @elements[name].any? { it.key == element.key }
        raise ArgumentError, "#{element.class.name.split('::').last} #{element.key.inspect} already exists"
      end

      @elements[name] = [*@elements[name], element].freeze
      element
    end

    def replace(name, old, new)
      @elements[name] = @elements[name].map { it.equal?(old) ? new : it }.freeze
      new
    end

    def find!(name, key, noun)
      Check.string(key, noun)
      @elements[name].find { it.key == key } || raise(ArgumentError, "no #{noun} #{key.inspect}")
    end

    def diff_collection(mine, theirs)
      sample = mine.first || theirs.first
      return {} unless sample

      changes = sample.keyed? ? diff_keyed(mine, theirs) : diff_unkeyed(mine, theirs)
      changes.reject { _2.empty? }
    end

    def diff_keyed(mine, theirs)
      mine = mine.to_h { [it.key, it] }
      theirs = theirs.to_h { [it.key, it] }
      modified = mine.filter_map { |key, old| { old:, new: theirs[key] } if theirs.key?(key) && !theirs[key].eql?(old) }
      { added: theirs.except(*mine.keys).values, removed: mine.except(*theirs.keys).values, modified: }
    end

    def diff_unkeyed(mine, theirs) = { added: without(theirs, mine), removed: without(mine, theirs) }

    # +list+ minus +other+ as multisets, in the order of +list+.
    def without(list, other)
      counts = other.tally
      list.reject { |item| counts[item].to_i.positive? && (counts[item] -= 1) }
    end
  end
end

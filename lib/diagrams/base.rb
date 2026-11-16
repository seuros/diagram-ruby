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
      # Diagrams::Base.from_h accepts any type; a subclass only its own.
      def from_h(hash)
        hash = Check.symbolize(hash)
        klass = diagram_class(hash[:type])
        return klass.from_h(hash) unless klass.equal?(self)

        data = hash.fetch(:data) { raise ArgumentError, 'diagram hash has no :data' }
        diagram = restore(data, version: hash.fetch(:version, 1))
        return diagram if hash[:checksum].nil? || hash[:checksum] == diagram.checksum

        raise ArgumentError, "checksum mismatch: expected #{hash[:checksum]}, content has #{diagram.checksum}"
      end

      def from_json(json) = from_h(JSON.parse(json))

      private

      # Settings through the constructor, then each element through its add_* method.
      def restore(data, version:)
        new(version:, **data.except(*collections.keys)).tap do |diagram|
          collections.each { |name, add| data.fetch(name, []).each { diagram.public_send(add, **it) } }
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

    def ==(other) = other.instance_of?(self.class) && other.content == content
    alias eql? ==

    def hash = [self.class, content].hash

    # Per collection, the elements added, removed and modified in +other+,
    # matched by Element#key (or whole value when an element has no key).
    # Collections without changes are left out.
    def diff(other)
      raise TypeError, "cannot diff #{self.class} with #{other.class}" unless other.instance_of?(self.class)

      @elements.to_h { |name, mine| [name, diff_collection(mine, other.public_send(name))] }.reject { _2.empty? }
    end

    private

    # Settings serialized ahead of the collections; subclasses extend this.
    def settings = { title: }

    def append(name, element)
      if element.key && @elements[name].any? { it.key == element.key }
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
      @elements[name].find { it.key == key } || raise(ArgumentError, "no #{noun} #{key.inspect}")
    end

    def diff_collection(mine, theirs)
      mine = mine.to_h { [it.key || it, it] }
      theirs = theirs.to_h { [it.key || it, it] }
      modified = mine.filter_map { |key, old| { old:, new: theirs[key] } if theirs.key?(key) && theirs[key] != old }
      { added: theirs.except(*mine.keys).values, removed: mine.except(*theirs.keys).values, modified: }
        .reject { _2.empty? }
    end
  end
end

module SeriesCalc
  class Term
    class << self
      def linkages
        @linkages ||= {}
      end

      protected

      def parent(name, identifier = name)
        add_linkage(:parent, name, identifier)
      end

      def child(name, identifier = name)
        add_linkage(:child, name, identifier)
      end

      private

      def add_linkage(type, name, identifier)
        if linkages.has_key?(identifier)
          raise "linkage already defined for: #{identifier.inspect}"
        end

        linkages[identifier] = ["unset_#{name}", "set_#{name}"].map(&:to_sym)

        class_eval %{
          attr_reader :#{name}

          protected

          def unset_#{name}
            if old_term = @#{name}
              detach_#{type}(old_term)
            end
            old_term
          end

          def set_#{name}(new_term)
            if new_term
              attach_#{type}(new_term)
            end
            @#{name}= new_term
          end
        }
      end
    end

    attr_reader :identifier
    attr_reader :parents
    attr_reader :children

    def initialize(identifier = nil)
      @identifier = identifier
      @parents  = []
      @children = []
      @dependents = nil
      @data = {}
      @value = nil
    end

    def attach_parent(new_parent)
      parents << new_parent
      new_parent.children << self

      new_parent.walk_each_at_and_above([self]) do |parent, path|
        if parent == self
          raise "cycle detected: #{path.map(&:identifier).map(&:inspect).join(' -> ')}"
        else
          parent.recalculate_value
        end
      end
      each_at_and_below(&:recalculate_dependents)
    end

    def detach_parent(parent)
      parents.delete(parent)
      parent.children.delete(self)

      parent.each_at_and_above(&:recalculate_value)
      each_at_and_below(&:recalculate_dependents)
    end

    def attach_child(new_child)
      children << new_child
      new_child.parents << self

      new_child.walk_each_at_and_below([self]) do |child, path|
        if child == self
          raise "cycle detected: #{path.map(&:identifier).map(&:inspect).join(' -> ')}"
        else
          child.recalculate_dependents
        end
      end
      each_at_and_above(&:recalculate_value)
    end

    def detach_child(child)
      child.detach_parent(self)
    end

    def recalculate_dependents
      @dependents = nil
    end

    def recalculate_dependents?
      @dependents.nil?
    end

    def dependents
      @dependents ||= begin
        dependents = []
        each_at_and_above do |node|
          dependents << node
        end
        dependents.uniq
      end
    end

    def set_data(delta, terms = {})
      linkages = self.class.linkages
      linkages.each_pair do |key, (unsetter, setter)|
        next unless delta.has_key?(key)
        send(unsetter)
      end
      linkages.each_pair do |key, (unsetter, setter)|
        next unless delta.has_key?(key)
        identifier = delta.delete(key)
        new_term = terms[identifier]
        send(setter, new_term)
      end

      unless delta.empty?
        @data.merge! delta
        dependents.each(&:recalculate_value)
      end
    end

    def unset_data
      self.class.linkages.each_pair do |key, (unsetter, setter)|
        send(unsetter)
      end
      @data.clear
      dependents.each(&:recalculate_value)
    end

    def recalculate_value
      @value = nil
    end

    def recalculate_value?
      @value.nil?
    end

    def value
      @value ||= calculate_value
    end

    def calculate_value
      raise NotImplementedError
    end

    protected

    def walk_each_at_and_above(path = [], &block) # :yields: node, path
      path.push self
      yield self, path
      walk(:parents, path, &block)
      path.pop
    end

    def walk_each_at_and_below(path = [], &block) # :yields: node, path
      path.push self
      yield self, path
      walk(:children, path, &block)
      path.pop
    end

    def walk(method_name, path = [self], &block)
      send(method_name).each do |node|
        path.push node
        block.call(node, path)
        node.walk(method_name, path, &block)
        path.pop
      end
    end

    def each_at_and_above(&block)
      yield self
      parents.each do |parent|
        parent.each_at_and_above(&block)
      end
      self
    end

    def each_at_and_below(&block)
      yield self
      children.each do |child|
        child.each_at_and_below(&block)
      end
      self
    end
  end
end

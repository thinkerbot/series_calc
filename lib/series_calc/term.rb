module SeriesCalc
  class Term
    class << self
      def subclass(&block)
        subclass = Class.new(Term)
        subclass.send(:define_method, :calculate_value, &block)
        subclass
      end

      def components
        @components ||= {}
      end

      def uses(component_name, term_class = nil, &block)
        index = component_terms.length
        components[component_name] = term_class || subclass(&block)
        class_eval %{
          def #{component_name}
            children[#{index}] or raise "#{component_name} term has not been attached"
          end
        }
      end
    end

    attr_reader :identifier
    attr_reader :parents
    attr_reader :children
    attr_reader :data

    def initialize(identifier = nil, data = nil)
      @identifier = identifier
      @parents  = []
      @children = []
      @dependents = nil
      @data = data
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

    def set_data(data)
      @data = data
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

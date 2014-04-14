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

    def walk_parents(&block) # :yields: node, path
      walk(:parents, &block)
    end

    def walk_children(&block) # :yields: node, path
      walk(:children, &block)
    end

    def attach_parents(*parents)
      parents = parents - self.parents
      parents.each do |parent|
        self.attach_parent(parent)
        parent.attach_child(self)
      end

      walk_parents do |node, path|
        if node == self
          raise "cycle detected: #{path.map(&:identifier).map(&:inspect).join(' -> ')}"
        end
      end

      parents.each do |parent|
        parent.each_at_and_above(&:recalculate_value)
      end
      each_at_and_below(&:recalculate_dependents)
    end

    def detach_parents(*parents)
      parents = self.parents & parents
      parents.each do |parent|
        self.detach_parent(parent)
        parent.detach_child(self)
      end

      parents.each do |parent|
        parent.each_at_and_above(&:recalculate_value)
      end
      each_at_and_below(&:recalculate_dependents)
    end

    def attach_children(*children)
      children = children - self.children
      children.each do |child|
        child.attach_parent(self)
        self.attach_child(child)
      end

      walk_children do |node, path|
        if node == self
          raise "cycle detected: #{path.map(&:identifier).map(&:inspect).join(' -> ')}"
        end
      end

      children.each do |child|
        child.each_at_and_below(&:recalculate_dependents)
      end
      each_at_and_above(&:recalculate_value)
    end

    def detach_children(*children)
      children = self.children & children
      children.each do |child|
        child.detach_parent(self)
        self.detach_child(child)
      end

      children.each do |child|
        child.each_at_and_below(&:recalculate_dependents)
      end
      each_at_and_above(&:recalculate_value)
    end

    def each_at_and_above(&block)
      unless block_given?
        return enum_for(:each_at_and_above)
      end

      yield self
      parents.each do |parent|
        parent.each_at_and_above(&block)
      end
      self
    end

    def each_at_and_below(&block)
      unless block_given?
        return enum_for(:each_at_and_below)
      end

      yield self
      children.each do |child|
        child.each_at_and_below(&block)
      end
      self
    end

    def recalculate_dependents
      @dependents = nil
    end

    def dependents
      @dependents ||= each_at_and_above.to_a.uniq.freeze
    end

    def data=(data)
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

    def walk(method_name, path = [self], &block)
      send(method_name).each do |node|
        path.push node
        block.call(node, path)
        node.walk(method_name, path, &block)
        path.pop
      end
    end

    def attach_parent(parent)
      parents << parent
    end

    def detach_parent(parent)
      parents.delete(parent)
    end

    def attach_child(child)
      children << child
    end

    def detach_child(child)
      children.delete(child)
    end
  end
end

module SeriesCalc
  class Node
    attr_reader :identifier
    attr_reader :parents
    attr_reader :children

    def initialize(identifier = nil)
      @identifier = identifier
      @parents  = []
      @children = []
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

    def walk_parents(&block) # :yields: node, path
      walk(:parents, &block)
    end

    def walk_children(&block) # :yields: node, path
      walk(:children, &block)
    end

    def attach_parents(*parents)
      new_parents = parents - self.parents
      new_parents.each do |parent|
        self.attach_parent(parent)
        parent.attach_child(self)
      end

      walk_parents do |node, path|
        if node == self
          raise "cycle detected: #{path.map(&:identifier).map(&:inspect).join(' -> ')}"
        end
      end
    end

    def detach_parents(*parents)
      existing_parents = self.parents & parents
      existing_parents.each do |parent|
        self.detach_parent(parent)
        parent.detach_child(self)
      end
    end

    def attach_children(*children)
      new_children = children - self.children
      new_children.each do |child|
        child.attach_parent(self)
        self.attach_child(child)
      end

      walk_children do |node, path|
        if node == self
          raise "cycle detected: #{path.map(&:identifier).map(&:inspect).join(' -> ')}"
        end
      end
    end

    def detach_children(*children)
      existing_children = self.children & children
      existing_children.each do |child|
        child.detach_parent(self)
        self.detach_child(child)
      end
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

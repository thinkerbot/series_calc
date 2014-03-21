module SeriesCalc
  class Node
    attr_reader :name
    attr_reader :parents
    attr_reader :children

    def initialize(name = nil)
      @name = name
      @parents  = []
      @children = []
    end

    def ancestors(&block)
      unless block_given?
        return enum_for(:ancestors)
      end

      parents.each do |parent|
        yield parent
        parent.ancestors(&block)
      end
      self
    end

    def ancestors_and_self(&block)
      unless block_given?
        return enum_for(:ancestors_and_self)
      end
      yield self
      ancestors(&block)
    end

    def descendants(&block)
      unless block_given?
        return enum_for(:descendants)
      end

      children.each do |child|
        yield child
        child.descendants(&block)
      end
      self
    end

    def descendants_and_self(&block)
      unless block_given?
        return enum_for(:descendants_and_self)
      end
      yield self
      descendants(&block)
    end

    def attach_parents(*parents)
      new_parents = parents - self.parents
      cyclics = descendants_and_self.to_a & new_parents

      if cyclics.any?
        raise "cannot attach parents: #{cyclics.map(&:name).inspect} (cycle detected)"
      end

      new_parents.each do |parent|
        self.attach_parent(parent)
        parent.attach_child(self)
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
      cyclics = ancestors_and_self.to_a & new_children

      if cyclics.any?
        raise "cannot attach children: #{cyclics.map(&:name).inspect} (cycle detected)"
      end

      new_children.each do |child|
        child.attach_parent(self)
        self.attach_child(child)
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

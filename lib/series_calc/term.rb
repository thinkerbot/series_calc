require 'series_calc/node'

module SeriesCalc
  class Term < Node
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

    attr_reader :data

    def initialize(identifier = nil, data = nil)
      super(identifier)
      @dependents = nil
      @data = data
      @value = nil
    end

    def recalculate_dependents
      @dependents = nil
    end

    def dependents
      @dependents ||= each_at_and_above.to_a.uniq.freeze
    end

    def data=(new_data)
      @data = new_data
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

    def attach_parents(*parents)
      super
      parents.each do |parent|
        parent.each_at_and_above(&:recalculate_value)
      end
      each_at_and_below(&:recalculate_dependents)
    end

    def detach_parents(*parents)
      super
      parents.each do |parent|
        parent.each_at_and_above(&:recalculate_value)
      end
      each_at_and_below(&:recalculate_dependents)
    end

    def attach_children(*children)
      super
      children.each do |child|
        child.each_at_and_below(&:recalculate_dependents)
      end
      each_at_and_above(&:recalculate_value)
    end

    def detach_children(*children)
      super
      children.each do |child|
        child.each_at_and_below(&:recalculate_dependents)
      end
      each_at_and_above(&:recalculate_value)
    end
  end
end

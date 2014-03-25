require 'series_calc/node'
require 'series_calc/calculator'

module SeriesCalc
  class Term < Node
    attr_reader :data
    attr_reader :calculator

    def initialize(name = nil, data = {}, &calculator)
      super(name)
      @data = data
      @dependencies = nil
      @values = nil
      @calculator = calculator || Calculator.new
    end

    def recalculate_dependents
      @dependents = nil
    end

    def dependents
      @dependents ||= each_at_and_above.to_a.uniq
    end

    def recalculate_value
      @values = nil
    end

    def values
      @values ||= calculate_values
    end

    def calculate_values
      values = {}

      calculator.call(data, values)

      children.each do |child|
        child.values.each_pair do |key, value|
          if current = values[key]
            values[key] = current + value
          else
            values[key] = value
          end
        end
      end

      values
    end

    def data=(new_data)
      @data = new_data
      dependents.each(&:recalculate_value)
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

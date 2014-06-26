require 'series_calc/timeframe'
require 'series_calc/dimension'

module SeriesCalc
  class Controller
    attr_reader :timeframe
    attr_reader :dimension_types
    attr_reader :dimensions
    attr_reader :updated_dimensions

    def initialize(timeframe, dimension_types = {})
      @timeframe = timeframe
      @dimension_types = dimension_types
      @dimensions = {}
      @updated_dimensions = []
    end

    def dimension_type_for(dimension_id)
      dimension_id.split('/', 2).first
    end

    def term_class_for(dimension_id)
      dimension_type = dimension_type_for(dimension_id)
      dimension_types[dimension_type] or raise("unknown dimension: #{dimension_type.inspect}")
    end

    def dimension_for(dimension_id)
      dimensions[dimension_id] ||= create_dimension(dimension_id)
    end

    def set_dimension_data(time, dimension_id, data)
      dimension = dimension_for(dimension_id)
      dimension.set_data(time, data)
      updated_dimensions << dimension

      self
    end

    def set_slot_data
      slots = timeframe.slots
      updated_dimensions.uniq.each do |dimension|
        set_data_on(slots, dimension)
      end
      updated_dimensions.clear
      self
    end

    def set_data_on(slots, dimension)
      dimension.each_data_for(slots) do |slot, data|
        term = slot[dimension.id]
        data.nil? ? term.unset_data : term.set_data(data, slot)
      end
    end

    def clear_unreachable_data
      min_slot_time = timeframe.min_slot_time
      dimensions.each_value do |dimension|
        dimension.clear_data_before(min_slot_time)
      end
      self
    end

    def advance_to(time)
      updated_slots = timeframe.advance_to(time)
      unless updated_slots.empty?
        dimensions.each_pair do |dimension_id, dimension|
          set_data_on(updated_slots, dimension)
        end
      end
      self
    end

    protected

    def create_dimension(dimension_id)
      term_class = term_class_for(dimension_id)
      timeframe.create_terms(dimension_id, term_class)
      Dimension.new([], dimension_id)
    end
  end
end

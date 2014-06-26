require 'series_calc/dimension'
require 'timeseries'

Time.zone = 'UTC'

module SeriesCalc
  class Timeframe
    attr_reader :timeseries
    attr_reader :slots

    def initialize(timeseries)
      if timeseries.n_steps.nil?
        raise "cannot create slots from unbounded timeseries"
      end

      @slots = []
      @timeseries = timeseries
      @timeseries.each_with_index do |time, index|
        @slots << Slot.new(time, index)
      end

      @slots_enum = @slots.cycle
      @current_timeseries_index = @timeseries.n_steps
      @current_slot_index = 0
    end

    def slot_times
      slots.map(&:time).sort
    end

    def min_slot_time
      slot_times.first
    end

    def next_slot
      @slots_enum.peek
    end

    def next_time
      timeseries.at(@current_timeseries_index + 1)
    end

    def advance_to(time)
      updated_slots = []

      while next_time < time
        next_slot = @slots_enum.next
        next_slot.time = next_time
        updated_slots << next_slot
        @current_timeseries_index += 1
      end

      updated_slots
    end

    def create_terms(dimension_id, term_class)
      slots.each_with_index do |slot, slot_index|
        slot[dimension_id] = term_class.new("#{dimension_id}@#{slot_index}")
      end
    end

    def delete_terms(dimension_id)
      slots.each do |slot|
        slot[dimension_id] = nil
      end
    end

    def terms_for(dimension_ids)
      unless block_given?
        return enum_for(:terms_for, dimension_ids)
      end

      slots.sort_by(&:time).each do |slot|
        terms = dimension_ids.map {|dimension_id| slot[dimension_id] }
        yield slot.time, terms
      end
    end

    def values_for(dimension_ids)
      unless block_given?
        return enum_for(:values_for, dimension_ids)
      end

      terms_for(dimension_ids).each do |time, terms|
        yield time, terms.map(&:value)
      end
    end

    def data_for(dimension_ids)
      unless block_given?
        return enum_for(:values_for, dimension_ids)
      end

      terms_for(dimension_ids).each do |time, terms|
        yield time, terms.map(&:data)
      end
    end
  end
end

require 'series_calc/dimension'
require 'timeseries'

Time.zone = 'UTC'

module SeriesCalc
  class Timeframe
    attr_reader :timeseries
    attr_reader :slots
    attr_reader :current_time
    attr_reader :offset

    def initialize(timeseries, current_time = nil)
      if timeseries.n_steps.nil?
        raise "cannot create slots from unbounded timeseries"
      end

      @slots = []
      @timeseries = timeseries
      @timeseries.each_with_index do |time, index|
        @slots << Slot.new(time, index)
      end
      @current_time = current_time || timeseries.stop_time
      @offset = @current_time - timeseries.stop_time

      @slots_enum = @slots.cycle
      @next_timeseries_index = @timeseries.n_steps
    end

    def slot_times
      slots.map(&:time).sort
    end

    def start_time
      slot_times.first
    end

    def stop_time
      slot_times.last
    end

    def next_slot
      @slots_enum.peek
    end

    def next_time
      timeseries.at(@next_timeseries_index)
    end

    def advance_to(current_time)
      updated_slots = []

      cutoff = current_time - offset
      while next_time <= cutoff
        next_slot = @slots_enum.next
        next_slot.time = next_time
        updated_slots << next_slot
        @next_timeseries_index += 1
      end
      @current_time = current_time

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

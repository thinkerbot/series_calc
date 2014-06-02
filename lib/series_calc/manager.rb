require 'series_calc/dimension'
require 'timeseries'

Time.zone = 'UTC'

module SeriesCalc
  class Manager
    class << self
      def default_start_time
        Time.parse(Time.now.strftime("%Y-%m-%d %H:00:00"))
      end

      def default_n_steps
        5
      end

      def default_period
        '15m'
      end

      def create(options = {})
        options = options.dup

        options[:start_time] ||= default_start_time
        options[:n_steps]    ||= default_n_steps
        options[:period]     ||= default_period
        timeseries = Timeseries.create(options)
        dimension_types = options[:dimension_types] || {}

        new(timeseries, dimension_types)
      end
    end

    attr_reader :timeseries
    attr_reader :slots
    attr_reader :dimension_types
    attr_reader :dimensions
    attr_reader :updated_dimensions

    def initialize(timeseries, dimension_types = {})
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

      @dimension_types = dimension_types
      @dimensions = {}
      @updated_dimensions = []
    end

    def slot_times
      slots.map(&:time).sort
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

      unless updated_slots.empty?
        dimensions.each_pair do |dimension_id, dimension|
          set_data_on(updated_slots, dimension)
        end
      end

      self
    end

    def clear_unreachable_data
      min_slot_time = slot_times.first
      dimensions.each_value do |dimension|
        dimension.clear_data_before(min_slot_time)
      end
    end

    def set_data(time, dimension_id, data)
      dimension = dimension_for(dimension_id)
      dimension.set_data(time, data)
      updated_dimensions << dimension

      self
    end

    def update_slot_data
      updated_dimensions.uniq.each do |dimension|
        set_data_on(slots, dimension)
      end
      updated_dimensions.clear
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

    def set_data_on(slots, dimension)
      dimension.each_data_for(slots) do |slot, data|
        term = slot[dimension.id]
        data.nil? ? term.unset_data : term.set_data(data, slot)
      end
    end

    def dimension_type_for(dimension_id)
      dimension_id.split('/', 2).first
    end

    def term_class_for(dimension_id)
      dimension_type = dimension_type_for(dimension_id)
      dimension_types[dimension_type] or raise("unknown dimension: #{dimension_type.inspect}")
    end

    def dimension_for(dimension_id)
      dimensions[dimension_id] ||= begin
        create_terms(dimension_id)
        Dimension.new([], dimension_id)
      end
    end

    def create_terms(dimension_id)
      term_class = term_class_for(dimension_id)
      slots.each_with_index do |slot, slot_index|
        slot[dimension_id] = term_class.new("#{dimension_id}@#{slot_index}")
      end
    end

    def delete_terms(dimension_id)
      slots.each do |slot|
        slot[dimension_id] = nil
      end
    end
  end
end

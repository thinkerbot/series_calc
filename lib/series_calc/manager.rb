require 'series_calc/node'
require 'series_calc/slot'
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
        options[:n_steps] ||= default_n_steps
        options[:period] ||= default_period
        timeseries = Timeseries.create(options)

        new(timeseries)
      end
    end

    attr_reader :timeseries
    attr_reader :slots

    def initialize(timeseries)
      if timeseries.n_steps.nil?
        raise "cannot create slots from unbounded timeseries"
      end

      @timeseries = timeseries
      @slots = timeseries.map {|step| Slot.new(step) }
      @slots_enum = slots.cycle
      @current_timeseries_index = timeseries.n_steps
      @current_slot_index = 0
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
      while next_time < time
        @slots_enum.next.time = next_time
        @current_timeseries_index += 1
      end
    end
  end
end

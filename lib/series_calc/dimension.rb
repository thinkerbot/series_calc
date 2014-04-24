require 'series_calc/slot'

module SeriesCalc
  class Dimension
    attr_reader :interval_data
    attr_reader :id

    def initialize(interval_data = [], id = nil)
      @interval_data = interval_data.sort_by(&:first)
      @id = id
    end

    def set_data(new_time, new_data)
      index = interval_data.index {|(time, data)| time > new_time } || interval_data.length
      interval_data.insert(index, [new_time, new_data])
    end

    def each_data_for(slots)
      index = 0
      time, data = nil, nil
      next_time, next_data = interval_data[index]

      sorted_slots = slots.sort_by(&:time)
      sorted_slots.each do |slot|
        slot_time = slot.time

        until (time.nil? || slot_time >= time) && (next_time.nil? || slot_time < next_time)
          index += 1
          time, data = next_time, next_data
          next_time, next_data = interval_data[index]
        end

        yield(slot, data)
      end

      slots
    end

    def clear_data_before(cutoff_time)
      while !interval_data.empty?
        if interval_data[0][0] < cutoff_time
          interval_data.shift
        else
          break
        end
      end
      self
    end
  end
end

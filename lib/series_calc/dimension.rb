require 'series_calc/term'
require 'series_calc/slot'

module SeriesCalc
  class Dimension
    attr_reader :interval_data
    attr_reader :terms_per_slot

    def initialize(slots = [], interval_data = [])
      @terms_per_slot = {}
      slots.each do |slot|
        terms_per_slot[slot] = []
      end
      self.interval_data = interval_data
    end

    def slots
      terms_per_slot.keys
    end

    def data_for_slot(slot)
      slot_time  = slot.time
      slot_data = nil

      interval_data.each do |(time, data)|
        if slot_time < time
          break
        else
          slot_data = data
        end
      end

      slot_data
    end

    def interval_data=(interval_data)
      @interval_data = interval_data.sort_by(&:first)
      terms_per_slot.each_pair do |slot, terms|
        slot_data = data_for_slot(slot)
        terms.each {|term| term.data = slot_data}
      end
    end

    def add_interval_data(time, data)
      self.interval_data = interval_data + [[time, data]]
    end

    def earliest_slot_time
      terms_per_slot.keys.map(&:time).min
    end

    def clear_unreachable_data
      cutoff = earliest_slot_time
      while !interval_data.empty?
        if interval_data[0][0] < cutoff
          interval_data.shift
        else
          break
        end
      end
      self
    end

    def register(slot, *terms)
      terms_per_slot[slot] |= terms

      slot_data = data_for_slot(slot)
      terms.each {|term| term.data = slot_data}

      self
    end

    def unregister(slot, *terms)
      terms_per_slot[slot] -= terms
      self
    end
  end
end

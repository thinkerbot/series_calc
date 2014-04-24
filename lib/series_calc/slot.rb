require 'series_calc/slot_term'

module SeriesCalc
  class Slot
    SLOT_DIMENSION_ID = 'slot'.freeze

    attr_reader :terms
    attr_reader :id

    def initialize(time = Time.now, id = nil)
      @terms = {SLOT_DIMENSION_ID => SlotTerm.new("time@#{id}", time)}
    end

    def time
      terms[SLOT_DIMENSION_ID].value
    end

    def time=(time)
      terms[SLOT_DIMENSION_ID].set_data(time, nil)
    end

    def [](dimension_id)
      terms[dimension_id] or raise("no term for dimension: #{dimension_id}")
    end

    def []=(dimension_id, term)
      terms[dimension_id] = term
    end

    def dimension_ids
      terms.keys
    end
  end
end

require 'series_calc/term'

module SeriesCalc
  class SlotTerm < Term
    def initialize(id = nil, time = nil)
      super(id)
      @value = time
    end

    def set_data(data, terms = {})
      @value = data
    end

    def unset_data
      @value = nil
    end

    def calculate_value
    end
  end
end

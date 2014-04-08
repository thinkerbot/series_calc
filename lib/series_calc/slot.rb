module SeriesCalc
  class Slot
    attr_reader :time

    def initialize(time = Time.now)
      @time = time
    end
  end
end

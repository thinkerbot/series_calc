module SeriesCalc
  class Slot
    attr_accessor :time

    def initialize(time = Time.now)
      @time = time
    end
  end
end

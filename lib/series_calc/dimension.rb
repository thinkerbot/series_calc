module SeriesCalc
  class Dimension
    attr_reader :interval_data

    def initialize(interval_data = [])
      self.interval_data = interval_data
    end

    def interval_data=(interval_data)
      @interval_data = interval_data.sort_by(&:first)
    end

    def add_interval_data(time, data)
      self.interval_data = interval_data + [[time, data]]
    end

    def data_for_times(times)
      times.map do |time|
        target_time = time
        target_data = nil

        interval_data.each do |(time, data)|
          if target_time < time
            break
          else
            target_data = data
          end
        end

        target_data
      end
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

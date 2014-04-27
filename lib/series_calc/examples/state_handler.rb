require 'series_calc/handler'

module SeriesCalc
  module Examples
    class StateHandler < Handler
      def call(time, request_type, id, data)
        manager.set_data(time, id, {:value => data.to_i})
      end
    end
  end
end

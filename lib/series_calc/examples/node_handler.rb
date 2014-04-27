require 'series_calc/handler'

module SeriesCalc
  module Examples
    class NodeHandler < Handler
      def call(time, request_type, id, data)
        manager.set_data(time, id, {:parent => data})
      end
    end
  end
end

require 'series_calc/handler'

module SeriesCalc
  module Examples
    class RequestHandler < Handler
      def call(time, request_type, id, data)
        dimension_ids = data.split(' ')
        yield time, 'REPLY', id, dimension_ids.join(' ')
        manager.values_for(dimension_ids) do |slot_time, values|
          yield slot_time, 'REPLY', id, values.join(' ')
        end
        yield time, 'REPLY', id, Array.new(dimension_ids.length, '-').join(' ')
      end
    end
  end
end

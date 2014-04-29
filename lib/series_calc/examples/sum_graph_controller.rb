require 'series_calc/command/controller'
require 'series_calc/examples/sum_term'

module SeriesCalc
  module Examples
    class SumGraphController < Command::Controller
      Line = SeriesCalc::Command::Line

      NODE    = 'NODE'.freeze
      STATE   = 'STATE'.freeze
      REQUEST = 'REQUEST'.freeze
      REPLY   = 'REPLY'.freeze

      attr_reader :logger

      def initialize(*args)
        super
        @logger = Logging.logger[self]
      end

      def route(line)
        time, type, id, data = \
        line.time, line.type, line.id, line.data

        case type
        when NODE
          node(time, id, data)
        when STATE
          state(time, id, data)
        when REQUEST
          start_time = Time.now
          request(time, id, data) do |otime, oid, odata|
            yield Line.new(otime, REPLY, oid, odata)
          end
          logger.info { "#{type} #{id} #{Time.now - start_time}s" }
        end
      end

      def node(time, id, data)
        manager.set_data(time, id, {:parent => data})
      end

      def state(time, id, data)
        manager.set_data(time, id, {:value => data.to_i})
      end

      def request(time, id, data)
        dimension_ids = data.split(' ')
        yield time, id, dimension_ids.join(' ')
        manager.values_for(dimension_ids) do |slot_time, values|
          yield slot_time, id, values.join(' ')
        end
        yield time, id, Array.new(dimension_ids.length, '-').join(' ')
      end

    end
  end
end

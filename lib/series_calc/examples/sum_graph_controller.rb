require 'series_calc/command/controller'
require 'series_calc/examples/sum_term'

module SeriesCalc
  module Examples
    class SumGraphController < Command::Controller
      class << self
        def dimension_types
          Hash.new(SumTerm)
        end
      end

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
          if @stop_time
            logger.info { "STATES #{start_time - @stop_time}s" }
          end
          request(time, id, data) do |otime, oid, odata|
            yield Line.new(otime, REPLY, oid, odata)
          end
          @stop_time = Time.now
          logger.info { "#{type} #{id} #{@stop_time- start_time}s" }
        end
      end

      def node(time, id, data)
        manager.set_data(time, id, {:parent => data})
        manager.update_slot_data
      end

      def state(time, id, data)
        manager.set_data(time, id, {:value => data.to_i})
      end

      def request(time, id, data)
        manager.advance_to(time)
        manager.clear_unreachable_data
        manager.update_slot_data

        dimension_ids = data.to_s.split(' ')
        yield time, id, dimension_ids.join(' ')
        manager.values_for(dimension_ids) do |slot_time, values|
          yield slot_time, id, values.join(' ')
        end
        yield time, id, Array.new(dimension_ids.length, '-').join(' ')
      end

    end
  end
end

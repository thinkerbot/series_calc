require 'series_calc/command/controller'
require 'series_calc/example/sum_term'

module SeriesCalc
  module Example
    class Controller < Command::Controller
      class << self
        def dimension_types
          dimension_types = super
          dimension_types.default = SumTerm
          dimension_types
        end
      end

      GET    = 'GET'.freeze
      PUT    = 'PUT'.freeze
      GRAPH  = 'GRAPH'.freeze
      DATA   = 'DATA'.freeze
      VALUES = 'VALUES'.freeze

      def get_data(message)
        timeframe.update_slot_data

        dimension_ids = message.content[:headers]
        enum = timeframe.data_for(dimension_ids)
        Message.new(message.creation_time, PUT, DATA, message.id, {:headers => dimension_ids, :rows => enum})
      end

      def get_values(message)
        timeframe.update_slot_data

        dimension_ids = message.content[:headers]
        enum = timeframe.values_for(dimension_ids)
        Message.new(message.creation_time, PUT, VALUES, message.id, {:headers => dimension_ids, :rows => enum})
      end

      def put_graph(message)
        timeframe.set_data(message.creation_time, message.id, {:parent => message.content[:headers][0]})
        timeframe.update_slot_data
        Message::NULL_MESSAGE
      end

      def put_data(message)
        timeframe.set_data(message.creation_time, message.id, {:value => message.content[:headers][0].to_i})
        Message::NULL_MESSAGE
      end

      def route(message, outputs = [])
        verb, type = message.verb, message.type

        case verb
        when GET
          case type
          when VALUES then get_values(message)
          when DATA then get_data(message)
          else unroutable(message)
          end
        when PUT
          case type
          when GRAPH then put_graph(message)
          when DATA  then put_data(message)
          else unroutable(message)
          end
        else unroutable(message)
        end
      end

      def unroutable(message)
      end
    end
  end
end

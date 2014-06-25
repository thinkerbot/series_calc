require 'series_calc/command/controller'
require 'series_calc/command/serializer'
require 'stringio'

module SeriesCalc
  module Command
    class Engine
      attr_reader :controller
      attr_reader :serializer

      def initialize(controller, serializer)
        @controller = controller
        @serializer = serializer
      end

      def process(stdin, stdout)
        while imessage = serializer.get(stdin)
          if imessage == Message::NULL_MESSAGE
            next
          end

          omessage = controller.route(imessage)
          if omessage == Message::NULL_MESSAGE
            next
          end

          serializer.put(omessage, stdout)
        end
      end

      def process_str(str)
        stdin  = StringIO.new(str)
        stdout = StringIO.new
        process(stdin, stdout)
        stdout.string
      end
    end
  end
end

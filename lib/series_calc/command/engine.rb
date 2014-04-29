require 'series_calc/command/controller'
require 'series_calc/command/serializer'
require 'stringio'

module SeriesCalc
  module Command
    class Engine
      attr_reader :serializer
      attr_reader :controller

      def initialize(controller, serializer)
        @controller = controller
        @serializer = serializer
      end

      def process(stdin, stdout)
        while line = serializer.gets(stdin)
          next if line == EMPTY_LINE

          outputs = []
          controller.route(line) do |output|
            outputs << output
          end

          serializer.puts(outputs, stdout)
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

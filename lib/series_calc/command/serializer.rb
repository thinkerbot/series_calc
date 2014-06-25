require 'series_calc/command/message'
require 'logging'

module SeriesCalc
  module Command
    class Serializer
      class << self
        def setup(config = {})
          options = {
            :unbuffer => config.fetch('unbuffer') { DEFAULT_CONFIG['unbuffer'] }
          }
          create(options)
        end

        def create(options = {})
          new(options)
        end
      end

      DEFAULT_CONFIG = {
        'unbuffer' => true,
      }

      attr_reader :unbuffer
      attr_reader :logger

      def initialize(options = {})
        @unbuffer = options.fetch(:unbuffer, true)
        @logger = Logging.logger[self]
      end

      def get(source)
      end

      def put(message, target)
      end
    end
  end
end

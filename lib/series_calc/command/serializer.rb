require 'series_calc/command/message'

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

      def initialize(options = {})
        @unbuffer = options.fetch(:unbuffer, true)
      end

      def gets(source)
      end

      def puts(message, target)
      end
    end
  end
end

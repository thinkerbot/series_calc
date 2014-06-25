require 'series_calc/timeframe'
require 'series_calc/command/message'

module SeriesCalc
  module Command
    class Controller
      class << self
        def default_start_time
          Time.parse(Time.now.strftime("%Y-%m-%d %H:00:00"))
        end

        def default_n_steps
          5
        end

        def default_period
          '15m'
        end

        def setup(config = {})
          options = {
            :start_time => config['start_time'],
            :n_steps    => config['n_steps'],
            :period     => config['period'],
          }
          create(options)
        end

        def create(options = {})
          options = options.dup

          options[:start_time] ||= default_start_time
          options[:n_steps]    ||= default_n_steps
          options[:period]     ||= default_period
          options[:dimension_types] ||= dimension_types
          timeframe  = Timeframe.new(options)

          new(timeframe)
        end

        def dimension_types
          {}
        end
      end

      DEFAULT_CONFIG = {
        'start_time'              => nil,
        'period'                  => nil,
        'n_steps'                 => nil,
      }

      attr_reader :timeframe
      attr_reader :logger

      def initialize(timeframe)
        @timeframe = timeframe
        @logger = Logging.logger[self]
      end

      def route(message)
        raise NotImplementedError
      end
    end
  end
end

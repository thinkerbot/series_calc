require 'series_calc/controller'
require 'series_calc/command/message'

module SeriesCalc
  module Command
    class Controller < SeriesCalc::Controller
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
          timeseries = Timeseries.create(
            :start_time => options[:start_time] || default_start_time,
            :n_steps    => options[:n_steps] || default_n_steps,
            :period     => options[:period] || default_period,
          )
          timeframe  = Timeframe.new(timeseries)

          new(timeframe, dimension_types)
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

      attr_reader :logger

      def initialize(timeframe, dimension_types = {})
        super
        @logger = Logging.logger[self]
      end

      def route(message)
        raise NotImplementedError
      end

      def unroutable(message)
      end
    end
  end
end

require 'series_calc/manager'
require 'series_calc/command/line'

module SeriesCalc
  module Command
    class Controller
      class << self
        def setup(config = {})
          start_time = config.fetch('start_time', nil)
          period     = config.fetch('period', nil)
          n_steps    = config.fetch('n_steps', nil)

          manager = Manager.create(
            :start_time => start_time,
            :period => period,
            :n_steps => n_steps,
            :dimension_types => dimension_types,
          )

          new(manager)
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

      attr_reader :manager

      def initialize(manager)
        @manager = manager
      end

      def route(line)
        raise NotImplementedError
      end
    end
  end
end

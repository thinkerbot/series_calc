require 'series_calc/manager'
require 'series_calc/command/line'

module SeriesCalc
  module Command
    class Controller
      class << self
        def setup(config = {})
          default_dimension_type = config.fetch('default_dimension_type', nil)
          if default_dimension_type
            default_dimension_type = default_dimension_type.constantize
          end

          raw_dimension_types = config.fetch('dimension_types', {})
          dimension_types = Hash.new(default_dimension_type)
          raw_dimension_types.each do |dimension_type, klass_name|
            dimension_types[dimension_type] = klass_name.constantize
          end

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
      end

      DEFAULT_CONFIG = {
        'start_time'              => nil,
        'period'                  => nil,
        'n_steps'                 => nil,
        'dimension_types'         => {},
        'default_dimension_type'  => nil,
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

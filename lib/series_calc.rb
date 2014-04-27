require 'series_calc/version'
require 'series_calc/engine'
require 'logging'

module SeriesCalc
  LOG_LEVELS = %w{debug info warn error}

  DEFAULT_OPTIONS = {
    'environment' => ENV['SERIES_CALC_ENVIRONMENT'] || 'development',
    'config_dir'  => ENV['SERIES_CALC_CONFIG_DIR'] || 'config'
  }

  DEFAULT_CONFIG = {
    # Timeseries
    'start_time'          => nil,
    'period'              => nil,
    'n_steps'             => nil,

    # Dimensions
    'requires'            => [],
    'dimension_types'     => {},
    'default_dimension_type' => nil,

    # Handlers
    'handlers'            => {},
    'default_handler'     => nil,

    # Logging
    'log_level'           => ENV['SERIES_CALC_LOG_LEVEL'] || 'warn',
    'log_format'          => ENV['SERIES_CALC_LOG_FORMAT'] || '[%d] %-5l %p %c %m\n',
    'log_datetime_format' => ENV['SERIES_CALC_LOG_DATETIME_FORMAT'] || '%Y-%m-%dT%H:%M:%S.%3NZ'
  }

  module_function

  def load_config(config_dir, environment)
    config_file = File.expand_path("#{environment}.yml", config_dir)
    env_config  = YAML.load_file(config_file) || {}
    DEFAULT_CONFIG.merge(env_config)
  end

  def setup(options = {})
    # Options
    config_dir = options['config_dir']
    environment = options['environment']
    log_level_offset = options['log_level_offset'] || 0
    config = load_config(config_dir, environment)

    # Logging
    Logging.init LOG_LEVELS

    log_level = config['log_level']
    level  = LOG_LEVELS.index(log_level) or raise("invalid log level: #{level.inspect}")
    level += log_level_offset

    format = config['log_format']
    datetime_format = config['log_datetime_format']

    min_level, max_level = 0, LOG_LEVELS.length - 1
    level = min_level if level < min_level
    level = max_level if level > max_level

    layout = Logging.layouts.pattern(:pattern => format, :date_pattern => datetime_format)
    Logging.appenders.stderr(:layout => layout)

    logger = Logging.logger.root
    logger.level = level
    logger.add_appenders "stderr"

    config['log_level'] = LOG_LEVELS[level]

    # Manager
    requires = config['requires']
    requires.each {|file| require file }

    default_dimension_type = config['default_dimension_type']
    if default_dimension_type
      default_dimension_type = default_dimension_type.constantize
    end
    raw_dimension_types = config['dimension_types']
    dimension_types = Hash.new(default_dimension_type)
    raw_dimension_types.each do |dimension_type, klass_name|
      dimension_types[dimension_type] = klass_name.constantize
    end

    start_time = config['start_time']
    period = config['period']
    n_steps = config['n_steps']

    manager = Manager.create(
      :start_time => start_time,
      :period => period,
      :n_steps => n_steps,
      :dimension_types => dimension_types
    )

    # Engine
    default_handler = config['default_handler']
    if default_handler
      default_handler = default_handler.constantize
    end
    raw_handlers = config['handlers']
    handlers = Hash.new(default_handler)
    raw_handlers.each do |handler, klass_name|
      handlers[handler] = klass_name.constantize.new(manager)
    end

    Engine.new(config, handlers)
  end

  def options(overrides = {})
    DEFAULT_OPTIONS.merge(overrides)
  end

  def version
    "series_calc version %s (%s)" % [VERSION, RELDATE]
  end
end

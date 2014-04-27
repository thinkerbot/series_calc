require 'series_calc/version'
require 'logging'

module SeriesCalc
  LOG_LEVELS = %w{debug info warn error}

  DEFAULT_OPTIONS = {
    'environment' => ENV['SERIES_CALC_ENVIRONMENT'] || 'development',
    'config_dir'  => ENV['SERIES_CALC_CONFIG_DIR'] || 'config'
  }

  DEFAULT_CONFIG = {
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
    config_dir = options['config_dir']
    environment = options['environment']
    log_level_offset = options['log_level_offset'] || 0

    Logging.init LOG_LEVELS

    config = load_config(config_dir, environment)
    log_level = config['log_level']
    level  = LOG_LEVELS.index(log_level) or raise("invalid log level: #{level.inspect}")
    level += log_level_offset

    format = config['log_format']
    datetime_format = options['log_datetime_format']

    min_level, max_level = 0, LOG_LEVELS.length - 1
    level = min_level if level < min_level
    level = max_level if level > max_level

    layout = Logging.layouts.pattern(:pattern => format, :date_pattern => datetime_format)
    Logging.appenders.stderr(:layout => layout)

    logger = Logging.logger.root
    logger.level = level
    logger.add_appenders "stderr"

    config['log_level'] = LOG_LEVELS[level]
    config
  end

  def options(overrides = {})
    DEFAULT_OPTIONS.merge(overrides)
  end

  def version
    "series_calc version %s (%s)" % [VERSION, RELDATE]
  end
end

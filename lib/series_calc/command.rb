require 'series_calc/command/engine'
require 'yaml'
require 'logging'

module SeriesCalc
  module Command
    module_function

    LOG_LEVELS = %w{debug info warn error}

    DEFAULT_CONFIG = {
      'log' => {
        'level'           => ENV['SERIES_CALC_LOG_LEVEL']  || 'warn',
        'format'          => ENV['SERIES_CALC_LOG_FORMAT'] || '[%d] %-5l %p %c %m\n',
        'datetime_format' => ENV['SERIES_CALC_LOG_DATETIME_FORMAT'] || '%Y-%m-%dT%H:%M:%S.%3NZ',
      },

      'controller' => Controller::DEFAULT_CONFIG.merge(
        'class'   => nil,
        'require' => nil,
      ),

      'serializer' => Serializer::DEFAULT_CONFIG.merge(
        'class'   => 'SeriesCalc::Command::Serializer',
        'require' => nil,
      ),
    }

    DEFAULT_OPTIONS = {
      :environment => ENV['SERIES_CALC_ENVIRONMENT'] || 'development',
      :config_dir  => ENV['SERIES_CALC_CONFIG_DIR']  || 'config',
      :log_offset  => 0,
    }

    module_function

    def load_config(options = {})
      options = DEFAULT_OPTIONS.merge(options)
      config_dir  = options[:config_dir]
      environment = options[:environment]
      log_offset  = options[:log_offset]

      config_file   = File.expand_path("#{environment}.yml", config_dir)
      global_config = YAML.load_file(config_file) || {}

      config = {}
      DEFAULT_CONFIG.each_pair do |object, default_object_config|
        object_config = {}
        global_configs = global_config[object] || {}
        default_object_config.each_pair do |key, default|
          user   = options["#{object}_#{key}".to_sym]
          global = global_configs[key]

          object_config[key] = \
          case
          when user   != nil then user
          when global != nil then global
          else default
          end
        end
        config[object] = object_config
      end

      log_level = config['log']['level']
      level = LOG_LEVELS.index(log_level) or raise("invalid log level: #{level.inspect}")
      level += log_offset

      min_level, max_level = 0, LOG_LEVELS.length - 1
      level = min_level if level < min_level
      level = max_level if level > max_level
      config['log']['level'] = LOG_LEVELS[level]

      config
    end

    def setup_logger(config)
      Logging.init LOG_LEVELS

      log_config = config['log']
      log_level = log_config['level']
      format = log_config['format']
      datetime_format = log_config['datetime_format']

      layout = Logging.layouts.pattern(:pattern => format, :date_pattern => datetime_format)
      Logging.appenders.stderr(:layout => layout)

      logger = Logging.logger.root
      logger.level = LOG_LEVELS.index(log_level)
      logger.add_appenders "stderr"

      logger
    end

    def setup_object(key, config)
      object_config = config[key]
      object_class = object_config['class'] or raise "no #{key} class specified"

      object_file = config.fetch('require', nil)
      object_file = object_class.underscore if object_file.nil?
      require object_file if object_file

      object_class.constantize.setup(object_config)
    end

    def setup(config)
      setup_logger(config)
      controller = setup_object('controller', config)
      serializer = setup_object('serializer', config)
      Engine.new(controller, serializer)
    end

    def options(overrides = {})
      DEFAULT_OPTIONS.merge(overrides)
    end
  end
end

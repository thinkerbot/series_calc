require 'series_calc/handler'

module SeriesCalc
  class Engine
    attr_reader :config
    attr_reader :handlers
    attr_reader :field_sep
    attr_reader :logger

    def initialize(config, handlers, field_sep = ' ')
      @config = config
      @handlers = handlers
      @field_sep = field_sep
      @logger = Logging.logger[self]
    end

    def route(request_type)
      handlers[request_type]
    end

    def process(stdin, stdout)
      while line = stdin.gets
        line.strip!
        next if line.empty?

        time_str, request_type, id, data = line.split(field_sep, 4)
        logger.debug { [time_str, request_type, id, data].inspect }

        time = Time.iso8601(time_str)
        handler = route(request_type)
        handler.call(time, request_type, id, data) do |otime, response_type, oid, odata|
          stdout.print otime.iso8601
          stdout.print field_sep
          stdout.print response_type
          stdout.print field_sep
          stdout.print oid
          stdout.print field_sep
          stdout.print odata
          stdout.print "\n"
        end
      end
    end
  end
end

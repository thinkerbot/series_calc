require 'series_calc/command/line'

module SeriesCalc
  module Command
    class Serializer
      class << self
        def setup(config = {})
          options = {
            :unbuffer => config.fetch('unbuffer', true)
          }
          new(options)
        end
      end

      DEFAULT_CONFIG = {
        'unbuffer' => true,
      }

      LINE_SEP = "\n".freeze
      FIELD_SEP = " ".freeze

      attr_reader :unbuffer

      def initialize(options = {})
        @unbuffer = options.fetch(:unbuffer, true)
      end

      def gets(source)
        line = source.gets(LINE_SEP)
        return nil if line.nil?

        line.strip!
        return EMPTY_LINE if line.empty?

        time_str, type, id, data = line.split(FIELD_SEP, 4)
        time = Time.iso8601(time_str)
        Line.new(time, type, id, data)
      end

      def puts(lines, target)
        lines.each do |line|
          target << line.time.iso8601
          target << FIELD_SEP
          target << line.type
          target << FIELD_SEP
          target << line.id
          target << FIELD_SEP
          target << line.data
          target << LINE_SEP
        end
        target.flush if unbuffer
        target
      end
    end
  end
end

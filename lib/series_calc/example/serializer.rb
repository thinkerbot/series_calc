require 'series_calc/command/serializer'

module SeriesCalc
  module Example
    class Serializer < Command::Serializer
      LINE_SEP  = "\n"
      FIELD_SEP = " "
      ROW_SEP = "\n  "
      COL_SEP = " "

      def parse_time(time_str)
        Time.iso8601(time_str)
      end

      def parse_table(content)
        headers_str, *row_strs = content.split(ROW_SEP)

        rows = []
        row_strs.each do |row_str|
          time_str, *values = row_str.split(COL_SEP)
          rows << [parse_time(time_str), values]
        end

        {
          :headers => headers_str.split(COL_SEP),
          :rows => rows,
        }
      end

      def gets(source)
        line = source.gets(LINE_SEP)
        return nil if line.nil?

        line.strip!
        return Message::NULL_MESSAGE if line.empty?

        creation_time_str, verb, type, id, content = line.split(FIELD_SEP, 5)
        creation_time = parse_time(creation_time_str)
        Message.new(creation_time, verb, type, id, parse_table(content))
      end

      def format_time(time)
        time.iso8601
      end

      def format_table(content)
        strs = []
        if headers = content[:headers]
          strs << headers.join(COL_SEP)
        end
        strs << ROW_SEP

        if rows = content[:rows]
          rows.each do |time, values|
            strs << format_time(time)
            strs << COL_SEP
            strs << values.join(COL_SEP)
            strs << ROW_SEP
          end
        end

        strs.join
      end

      def puts(message, target)
        target << format_time(message.creation_time)
        target << FIELD_SEP
        target << message.verb
        target << FIELD_SEP
        target << message.type
        target << FIELD_SEP
        target << message.id
        target << FIELD_SEP
        target << format_table(message.content)
        target << LINE_SEP

        target.flush if unbuffer
        target
      end
    end
  end
end

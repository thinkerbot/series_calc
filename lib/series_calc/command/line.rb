module SeriesCalc
  module Command
    Line = Struct.new(:time, :type, :id, :data)
    EMPTY_LINE = Object.new.freeze
  end
end

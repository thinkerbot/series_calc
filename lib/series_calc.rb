require 'series_calc/version'

module SeriesCalc
  module_function

  def version
    "series_calc version %s (%s)" % [VERSION, RELDATE]
  end
end

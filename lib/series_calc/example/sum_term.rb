require 'series_calc/term'

module SeriesCalc
  module Example
    class SumTerm < Term
      parent :parent

      def calculate_value
        value = @data[:value] || 0
        children.each do |child|
          value += child.value
        end
        value
      end
    end
  end
end

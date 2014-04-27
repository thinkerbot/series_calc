require 'series_calc/term'

module SeriesCalc
  module Examples
    class NegTerm < SeriesCalc::Term
      parent :parent

      def calculate_value
        value = -1 * (@data[:value] || 0)
        children.each do |child|
          value -= child.value
        end
        value
      end
    end
  end
end

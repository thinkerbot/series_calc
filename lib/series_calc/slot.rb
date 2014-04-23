require 'series_calc/term'

module SeriesCalc
  class Slot
    TIME_DIMENSION = 'time'.freeze

    attr_reader :terms

    def initialize(time = Time.now)
      @terms = {TIME_DIMENSION => time}
    end

    def time
      terms[TIME_DIMENSION]
    end

    def time=(time)
      terms[TIME_DIMENSION] = time
    end

    def [](term_identifier)
      terms[term_identifier] or raise("unknown term: #{term_identifier}")
    end

    def []=(term_identifier, term)
      if term && terms.has_key?(term_identifier)
        raise "term already exists: #{term_identifier}"
      end
      terms[term_identifier] = term
    end

    def term_identifiers
      terms.keys
    end
  end
end

require 'series_calc/slot_term'

module SeriesCalc
  class Slot
    SLOT_DIMENSION_ID = 'slot'.freeze

    attr_reader :terms
    attr_reader :identifier

    def initialize(time = Time.now, identifier = nil)
      @terms = {SLOT_DIMENSION_ID => SlotTerm.new("time@#{identifier}", time)}
    end

    def time
      terms[SLOT_DIMENSION_ID].value
    end

    def time=(time)
      terms[SLOT_DIMENSION_ID].set_data(time, nil)
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

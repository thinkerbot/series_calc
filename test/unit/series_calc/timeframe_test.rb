#!/usr/bin/env ruby
require File.expand_path('../../helper', __FILE__)
require 'series_calc/timeframe'

class SeriesCalc::TimeframeTest < Test::Unit::TestCase
  Timeframe = SeriesCalc::Timeframe
  Dimension = SeriesCalc::Dimension

  attr_reader :now

  def setup
    @now = Time.zone.now
  end

  class SumTerm < SeriesCalc::Term
    def calculate_value
      value = @data[:value] || 0
      children.each do |child|
        value += child.value
      end
      value
    end
  end

  class NegativeSumTerm < SeriesCalc::Term
    def calculate_value
      value = -1 * (@data[:value] || 0)
      children.each do |child|
        value -= child.value
      end
      value
    end
  end

  #
  # new
  #

  def test_new_makes_a_5_step_15min_timeframe
    timeframe = Timeframe.new(:start_time => '2010-01-01')
    assert_equal %w{
      2010-01-01T00:00:00Z
      2010-01-01T00:15:00Z
      2010-01-01T00:30:00Z
      2010-01-01T00:45:00Z
      2010-01-01T01:00:00Z
    }, timeframe.slots.map(&:time).map(&:iso8601)
  end

  #
  # initialize
  #

  def test_initialize_news_slots_from_timeseries
    timeframe = Timeframe.new(
      :start_time => '2010-01-01',
      :n_steps => 4,
      :period  => '10s'
    )
    assert_equal %w{
      2010-01-01T00:00:00Z
      2010-01-01T00:00:10Z
      2010-01-01T00:00:20Z
      2010-01-01T00:00:30Z
    }, timeframe.slots.map(&:time).map(&:iso8601)
  end

  def test_initialize_raises_error_for_unbounded_timeseries
    error = assert_raises(RuntimeError) { Timeframe.new(:n_steps => nil) }
    assert_equal "cannot create slots from unbounded timeseries", error.message
  end

  #
  # slot_times
  #

  def test_slot_times_returns_sorted_slot_times
    timeframe = Timeframe.new :start_time => '2010-01-01'
    assert_equal %w{
      2010-01-01T00:00:00Z
      2010-01-01T00:15:00Z
      2010-01-01T00:30:00Z
      2010-01-01T00:45:00Z
      2010-01-01T01:00:00Z
    }, timeframe.slot_times.map(&:iso8601)
  end

  #
  # advance_to
  #

  def test_advance_to_rotates_slot_times_through_timeseries_until_latest_slot_time_is_before_target
    timeframe = Timeframe.new :start_time => '2010-01-01'

    target_time = Time.zone.parse('2010-01-01T02:35:00')
    timeframe.advance_to(target_time)

    assert_equal %w{
      2010-01-01T01:30:00Z
      2010-01-01T01:45:00Z
      2010-01-01T02:00:00Z
      2010-01-01T02:15:00Z
      2010-01-01T02:30:00Z
    }, timeframe.slot_times.map(&:iso8601)
  end

  #
  # term_class_for
  #

  def test_dimension_for_returns_term_class_for_id
    timeframe = Timeframe.new(:dimension_types => {
      'a' => SumTerm,
      'b' => NegativeSumTerm,
    })
    assert_equal SumTerm, timeframe.term_class_for('a/one')
    assert_equal NegativeSumTerm, timeframe.term_class_for('b/one')
  end

  #
  # dimension_for
  #

  def test_dimension_for_initializes_terms_in_each_slot_if_needed
    timeframe = Timeframe.new(:dimension_types => {'a' => SumTerm})
    assert_equal Dimension, timeframe.dimension_for('a/one').class

    terms = timeframe.slots.map {|slot| slot['a/one'] }
    assert_equal [
      ['a/one@0', SumTerm],
      ['a/one@1', SumTerm],
      ['a/one@2', SumTerm],
      ['a/one@3', SumTerm],
      ['a/one@4', SumTerm],
    ], terms.map {|term| [term.id, term.class] }
    
  end

  def test_dimension_for_raises_error_for_unregistered_type
    timeframe = Timeframe.new
    err = assert_raises(RuntimeError) { timeframe.dimension_for('unknown/one') }
    assert_equal 'unknown dimension: "unknown"', err.message
  end
end

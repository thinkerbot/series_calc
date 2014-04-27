#!/usr/bin/env ruby
require File.expand_path('../../helper', __FILE__)
require 'series_calc/manager'

class SeriesCalc::ManagerTest < Test::Unit::TestCase
  Manager = SeriesCalc::Manager
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
  # create
  #

  def test_create_makes_a_5_step_15min_manager
    manager = Manager.create(:start_time => '2010-01-01')
    assert_equal %w{
      2010-01-01T00:00:00Z
      2010-01-01T00:15:00Z
      2010-01-01T00:30:00Z
      2010-01-01T00:45:00Z
      2010-01-01T01:00:00Z
    }, manager.slots.map(&:time).map(&:iso8601)
  end

  #
  # initialize
  #

  def test_initialize_creates_slots_from_timeseries
    timeseries = Timeseries.create(
      :start_time => '2010-01-01',
      :n_steps => 4,
      :period  => '10s'
    )
    manager = Manager.new(timeseries)
    assert_equal %w{
      2010-01-01T00:00:00Z
      2010-01-01T00:00:10Z
      2010-01-01T00:00:20Z
      2010-01-01T00:00:30Z
    }, manager.slots.map(&:time).map(&:iso8601)
  end

  def test_initialize_raises_error_for_unbounded_timeseries
    timeseries = Timeseries.create(:n_steps => nil)
    error = assert_raises(RuntimeError) { Manager.new(timeseries) }
    assert_equal "cannot create slots from unbounded timeseries", error.message
  end

  #
  # slot_times
  #

  def test_slot_times_returns_sorted_slot_times
    manager = Manager.create :start_time => '2010-01-01'
    assert_equal %w{
      2010-01-01T00:00:00Z
      2010-01-01T00:15:00Z
      2010-01-01T00:30:00Z
      2010-01-01T00:45:00Z
      2010-01-01T01:00:00Z
    }, manager.slot_times.map(&:iso8601)
  end

  #
  # advance_to
  #

  def test_advance_to_rotates_slot_times_through_timeseries_until_latest_slot_time_is_before_target
    manager = Manager.create :start_time => '2010-01-01'

    target_time = Time.zone.parse('2010-01-01T02:35:00')
    manager.advance_to(target_time)

    assert_equal %w{
      2010-01-01T01:30:00Z
      2010-01-01T01:45:00Z
      2010-01-01T02:00:00Z
      2010-01-01T02:15:00Z
      2010-01-01T02:30:00Z
    }, manager.slot_times.map(&:iso8601)
  end

  #
  # term_class_for
  #

  def test_dimension_for_returns_term_class_for_id
    manager = Manager.create(:dimension_types => {
      'a' => SumTerm,
      'b' => NegativeSumTerm,
    })
    assert_equal SumTerm, manager.term_class_for('a/one')
    assert_equal NegativeSumTerm, manager.term_class_for('b/one')
  end

  #
  # dimension_for
  #

  def test_dimension_for_initializes_terms_in_each_slot_if_needed
    manager = Manager.create(:dimension_types => {'a' => SumTerm})
    assert_equal Dimension, manager.dimension_for('a/one').class

    terms = manager.slots.map {|slot| slot['a/one'] }
    assert_equal [
      ['a/one@0', SumTerm],
      ['a/one@1', SumTerm],
      ['a/one@2', SumTerm],
      ['a/one@3', SumTerm],
      ['a/one@4', SumTerm],
    ], terms.map {|term| [term.id, term.class] }
    
  end

  def test_dimension_for_raises_error_for_unregistered_type
    manager = Manager.create
    err = assert_raises(RuntimeError) { manager.dimension_for('unknown/one') }
    assert_equal 'unknown dimension: "unknown"', err.message
  end
end

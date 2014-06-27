#!/usr/bin/env ruby
require File.expand_path('../../helper', __FILE__)
require 'series_calc/timeframe'

class SeriesCalc::TimeframeTest < Test::Unit::TestCase
  Timeframe = SeriesCalc::Timeframe

  def timeseries
    @timeseries ||= Timeseries.create(
      :start_time => '2010-01-01',
      :n_steps => 5,
      :period => '15m',
    )
  end

  #
  # initialize
  #

  def test_initialize_creates_slots_from_timeseries
    timeframe = Timeframe.new(timeseries)
    assert_equal %w{
      2010-01-01T00:00:00Z
      2010-01-01T00:15:00Z
      2010-01-01T00:30:00Z
      2010-01-01T00:45:00Z
      2010-01-01T01:00:00Z
    }, timeframe.slots.map(&:time).map(&:iso8601)
  end

  def test_initialize_sets_current_time_to_timeseries_stop_time
    timeframe = Timeframe.new(timeseries)
    assert_equal '2010-01-01T01:00:00Z' , timeframe.current_time.iso8601
  end

  def test_initialize_raises_error_for_unbounded_timeseries
    timeseries = Timeseries.create(:n_steps => nil)
    error = assert_raises(RuntimeError) { Timeframe.new(timeseries) }
    assert_equal "cannot create slots from unbounded timeseries", error.message
  end

  #
  # slot_times
  #

  def test_slot_times_returns_sorted_slot_times
    timeframe = Timeframe.new(timeseries)
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

  def test_advance_to_sets_current_time_and_rotates_slot_times_through_timeseries_until_stop_time_is_before_target
    timeframe = Timeframe.new(timeseries)
    target_time = Time.zone.parse('2010-01-01T02:35:00Z')
    timeframe.advance_to(target_time)

    assert_equal %w{
      2010-01-01T01:30:00Z
      2010-01-01T01:45:00Z
      2010-01-01T02:00:00Z
      2010-01-01T02:15:00Z
      2010-01-01T02:30:00Z
    }, timeframe.slot_times.map(&:iso8601)
    assert_equal '2010-01-01T02:35:00Z', timeframe.current_time.iso8601
  end

  def test_advance_to_sets_current_time_even_if_slots_do_not_advance
    timeframe = Timeframe.new(timeseries)
    target_time = Time.zone.parse('2010-01-01T00:14:59Z')
    timeframe.advance_to(target_time)

    assert_equal %w{
      2010-01-01T00:00:00Z
      2010-01-01T00:15:00Z
      2010-01-01T00:30:00Z
      2010-01-01T00:45:00Z
      2010-01-01T01:00:00Z
    }, timeframe.slot_times.map(&:iso8601)
    assert_equal '2010-01-01T00:14:59Z', timeframe.current_time.iso8601
  end

  def test_advance_to_preserves_initial_offset_between_stop_time_and_curent_time
    current_time = Time.zone.parse('2010-01-01T02:00:00Z')
    timeframe = Timeframe.new(timeseries, current_time)

    target_time = Time.zone.parse('2010-01-01T02:35:00Z')
    timeframe.advance_to(target_time)

    assert_equal %w{
      2010-01-01T00:30:00Z
      2010-01-01T00:45:00Z
      2010-01-01T01:00:00Z
      2010-01-01T01:15:00Z
      2010-01-01T01:30:00Z
    }, timeframe.slot_times.map(&:iso8601)
    assert_equal '2010-01-01T02:35:00Z', timeframe.current_time.iso8601
  end

  def test_advance_to_preserves_positive_offset
    current_time = Time.zone.parse('2010-01-01T00:00:00Z')
    timeframe = Timeframe.new(timeseries.offset(4), current_time)

    assert_equal '2010-01-01T00:00:00Z', timeframe.current_time.iso8601
    assert_equal '2010-01-01T01:00:00Z', timeframe.start_time.iso8601

    target_time = Time.zone.parse('2010-01-01T02:35:00Z')
    timeframe.advance_to(target_time)

    assert_equal %w{
      2010-01-01T03:30:00Z
      2010-01-01T03:45:00Z
      2010-01-01T04:00:00Z
      2010-01-01T04:15:00Z
      2010-01-01T04:30:00Z
    }, timeframe.slot_times.map(&:iso8601)
    assert_equal '2010-01-01T02:35:00Z', timeframe.current_time.iso8601
  end
end

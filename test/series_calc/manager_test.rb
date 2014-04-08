#!/usr/bin/env ruby
require File.expand_path('../../helper', __FILE__)
require 'series_calc/manager'

class SeriesCalc::ManagerTest < Test::Unit::TestCase
  Manager = SeriesCalc::Manager

  attr_reader :now

  def setup
    @now = Time.zone.now
  end

  #
  # create
  #

  def test_create_makes_a_5_step_15min_manager
    manager = Manager.create :start_time => '2010-01-01'
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
    manager = Manager.new timeseries
    assert_equal %w{
      2010-01-01T00:00:00Z
      2010-01-01T00:00:10Z
      2010-01-01T00:00:20Z
      2010-01-01T00:00:30Z
    }, manager.slots.map(&:time).map(&:iso8601)
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
end

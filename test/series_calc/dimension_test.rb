#!/usr/bin/env ruby
require File.expand_path('../../helper', __FILE__)
require 'series_calc/dimension'

class SeriesCalc::DimensionTest < Test::Unit::TestCase
  Dimension = SeriesCalc::Dimension

  attr_reader :now

  def setup
    @now = Time.now
  end

  def times_for(*offsets)
    offsets.map {|offset| now + offset }
  end

  #
  # initialize
  #

  def test_initialize_sets_interval_data
    dimension = Dimension.new([[now, :x]])
    assert_equal [[now, :x]], dimension.interval_data
  end

  #
  # data_for_times
  #

  def test_data_for_times_returns_data_for_interval_containing__time_or_nil
    times = times_for(-1, 0, 1, 2, 3)
    dimension = Dimension.new([
      [now    , :x],
      [now + 2, :y],
    ])

    assert_equal [nil, :x, :x, :y, :y], dimension.data_for_times(times)
  end

  #
  # interval_data=
  #

  def test_set_interval_data_can_recieve_interval_data_out_of_order
    dimension = Dimension.new
    dimension.interval_data = [
      [now + 2, :y],
      [now    , :x],
    ]

    assert_equal [:x], dimension.data_for_times([now])
  end

  #
  # add_interval_data
  #

  def test_add_interval_data_appends_time_data_to_interval_data
    times = times_for(-1, 0, 1, 2, 3)
    dimension = Dimension.new([
      [now, :x],
    ])

    assert_equal [nil, :x, :x, :x, :x], dimension.data_for_times(times)

    dimension.add_interval_data(now + 2, :y)

    assert_equal [nil, :x, :x, :y, :y], dimension.data_for_times(times)
  end

  def test_add_interval_data_can_receive_data_out_of_order
    times = times_for(-1, 0, 1, 2, 3)
    dimension = Dimension.new([
      [now + 2, :y],
    ])

    assert_equal [nil, nil, nil, :y, :y], dimension.data_for_times(times)

    dimension.add_interval_data(now, :x)

    assert_equal [nil, :x, :x, :y, :y], dimension.data_for_times(times)
  end

  #
  # clear_data_before
  #

  def test_clear_data_before_removes_interval_data_prior_to_cutoff
    dimension = Dimension.new([
      [now - 1, :x],
      [now    , :y],
      [now + 2, :z],
    ])

    dimension.clear_data_before(now)

    assert_equal [
      [now    , :y],
      [now + 2, :z],
    ], dimension.interval_data
  end
end

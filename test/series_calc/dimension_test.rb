#!/usr/bin/env ruby
require File.expand_path('../../helper', __FILE__)
require 'series_calc/dimension'

class SeriesCalc::DimensionTest < Test::Unit::TestCase
  Dimension = SeriesCalc::Dimension
  Slot = SeriesCalc::Slot

  attr_reader :now

  def setup
    @now = Time.now
  end

  def slots_for(*offsets)
    offsets.map {|offset| Slot.new(now + offset) }
  end

  def assert_data_for_slots(expected, dimension, slots)
    slot_data = []
    dimension.each_data_for(slots) do |slot, data|
      slot_data[slots.index(slot)] = data
    end
    assert_equal expected, slot_data
  end

  #
  # initialize
  #

  def test_initialize_sets_interval_data
    dimension = Dimension.new([[now, :x]])
    assert_equal [[now, :x]], dimension.interval_data
  end

  #
  # each_data_for
  #

  def test_each_data_for_returns_data_for_interval_containing_slot_time_or_nil
    slots = slots_for(-1, 0, 1, 2, 3)
    dimension = Dimension.new([
      [now    , :x],
      [now + 2, :y],
    ])

    assert_data_for_slots [nil, :x, :x, :y, :y], dimension, slots
  end

  def test_each_data_for_allows_slots_to_be_out_of_order
    slots = slots_for(-1, 0, 1, 2, 3)
    dimension = Dimension.new([
      [now    , :x],
      [now + 2, :y],
    ])

    assert_data_for_slots [:y, :y, :x, :x, nil], dimension, slots.reverse
  end

  #
  # set_data
  #

  def test_set_data_inserts_data_into_existing
    slots = slots_for(-1, 0, 1, 2, 3)
    dimension = Dimension.new([
      [now, :x],
    ])
    assert_data_for_slots [nil, :x, :x, :x, :x], dimension, slots

    dimension.set_data(now + 2, :y)
    assert_data_for_slots [nil, :x, :x, :y, :y], dimension, slots
  end

  def test_set_data_can_receive_data_out_of_order
    slots = slots_for(-1, 0, 1, 2, 3)
    dimension = Dimension.new([
      [now + 2, :y],
    ])
    assert_data_for_slots [nil, nil, nil, :y, :y], dimension, slots

    dimension.set_data(now, :x)
    assert_data_for_slots [nil, :x, :x, :y, :y], dimension, slots
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

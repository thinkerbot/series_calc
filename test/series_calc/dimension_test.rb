#!/usr/bin/env ruby
require File.expand_path('../../helper', __FILE__)
require 'series_calc/dimension'

class SeriesCalc::DimensionTest < Test::Unit::TestCase
  Dimension = SeriesCalc::Dimension
  Term = SeriesCalc::Term
  Slot = SeriesCalc::Slot

  #
  # initialize
  #

  def test_initialize_sets_slots_as_keys_for_terms_per_slot
    slots = 3.times.map { Slot.new }
    dimension = Dimension.new(slots)
    assert_equal slots, dimension.terms_per_slot.keys
  end

  #
  # slots
  #

  def test_slots_returns_array_of_slots
    slots = 3.times.map { Slot.new }
    dimension = Dimension.new(slots)
    assert_equal slots, dimension.slots
  end

  #
  # data_for_slot
  #

  def test_data_for_slot_returns_data_for_interval_containing_slot_time_or_nil
    now = Time.now
    a = Slot.new(now - 1)
    b = Slot.new(now)
    c = Slot.new(now + 1)
    d = Slot.new(now + 2)
    e = Slot.new(now + 3)

    dimension = Dimension.new([a, b, c, d, e], [
      [now    , :x],
      [now + 2, :y],
    ])

    assert_equal nil, dimension.data_for_slot(a)
    assert_equal  :x, dimension.data_for_slot(b)
    assert_equal  :x, dimension.data_for_slot(c)
    assert_equal  :y, dimension.data_for_slot(d)
    assert_equal  :y, dimension.data_for_slot(e)
  end

  #
  # interval_data=
  #

  def test_set_interval_data_updates_data_for_all_terms
    now = Time.now
    sa, ta = Slot.new(now - 1), Term.new
    sb, tb = Slot.new(now)    , Term.new
    sc, tc = Slot.new(now + 1), Term.new
    sd, td = Slot.new(now + 2), Term.new
    se, te = Slot.new(now + 3), Term.new
    slots = [sa, sb, sc, sd, se]
    terms = [ta, tb, tc, td, te]

    dimension = Dimension.new(slots)
    dimension.register(sa, ta)
    dimension.register(sb, tb)
    dimension.register(sc, tc)
    dimension.register(sd, td)
    dimension.register(se, te)

    assert_equal [nil, nil, nil, nil, nil], terms.map(&:data)

    dimension.interval_data = [
      [now    , :x],
      [now + 2, :y],
    ]

    assert_equal [nil, :x, :x, :y, :y], terms.map(&:data)
  end

  def test_set_interval_data_can_recieve_interval_data_out_of_order
    now = Time.now
    a = Slot.new(now)

    dimension = Dimension.new([a])
    dimension.interval_data = [
      [now + 2, :y],
      [now    , :x],
    ]

    assert_equal :x, dimension.data_for_slot(a)
  end

  #
  # add_interval_data
  #

  def test_add_interval_data_reassigns_data_to_terms_as_needed
    now = Time.now
    sa, ta = Slot.new(now - 1), Term.new
    sb, tb = Slot.new(now)    , Term.new
    sc, tc = Slot.new(now + 1), Term.new
    sd, td = Slot.new(now + 2), Term.new
    se, te = Slot.new(now + 3), Term.new
    slots = [sa, sb, sc, sd, se]
    terms = [ta, tb, tc, td, te]

    dimension = Dimension.new(slots, [
      [now, :x],
    ])
    dimension.register(sa, ta)
    dimension.register(sb, tb)
    dimension.register(sc, tc)
    dimension.register(sd, td)
    dimension.register(se, te)

    assert_equal [nil, :x, :x, :x, :x], terms.map(&:data)

    dimension.add_interval_data(now + 2, :y)

    assert_equal [nil, :x, :x, :y, :y], terms.map(&:data)
  end

  #
  # clear_unreachable_data
  #

  def test_clear_unreachable_data_removes_interval_data_prior_to_earliest_slot_time
    now = Time.now
    a = Slot.new(now)
    b = Slot.new(now + 1)

    dimension = Dimension.new([a, b], [
      [now - 1, :x],
      [now    , :y],
      [now + 2, :z],
    ])

    dimension.clear_unreachable_data
    assert_equal [
      [now    , :y],
      [now + 2, :z],
    ], dimension.interval_data
  end

  #
  # register
  #

  def test_register_records_term_as_belonging_to_slot
    term, slot = Term.new, Slot.new
    dimension = Dimension.new([slot])
    dimension.register(slot, term)
    assert_equal [term], dimension.terms_per_slot[slot]
  end

  def test_register_records_does_not_double_register_term
    term, slot = Term.new, Slot.new
    dimension = Dimension.new([slot])
    dimension.register(slot, term, term)
    dimension.register(slot, term, term)
    assert_equal [term], dimension.terms_per_slot[slot]
  end

  def test_register_sets_data_on_term_corresponding_to_slot_time
    term, slot = Term.new, Slot.new

    dimension = Dimension.new([slot], [
      [slot.time - 1, :pre ],
      [slot.time    , :data],
      [slot.time + 1, :post],
    ])
    dimension.register(slot, term)

    assert_equal :data, term.data
  end

  #
  # unregister
  #

  def test_unregister_removes_term_from_belonging_to_slot
    a, b, c, slot = Term.new, Term.new, Term.new, Slot.new
    dimension = Dimension.new([slot])
    dimension.register(slot, a, b, c)
    assert_equal [a, b, c], dimension.terms_per_slot[slot]

    dimension.unregister(slot, b)
    assert_equal [a, c], dimension.terms_per_slot[slot]
  end
end

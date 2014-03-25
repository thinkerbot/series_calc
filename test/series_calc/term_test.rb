#!/usr/bin/env ruby
require File.expand_path("../../helper", __FILE__)
require "series_calc/term"

class SeriesCalc::TermTest < Test::Unit::TestCase
  Term = SeriesCalc::Term

  #
  # recalculate_values
  #

  def test_recalculate_values_calls_calculator_to_get_values
    term = Term.new {|data, values| values[:key] = :value }
    values = term.calculate_values
    assert_equal :value, values[:key]
  end

  def test_recalculate_values_merges_and_sums_values_from_children
    a, b, c = %w{a b c}.map do |name|
      Term.new(name) do |data, values|
        values[:count] = 1
        values[name.to_sym] = 1
      end
    end

    a.attach_children(b)
    b.attach_children(c)

    assert_equal({
      :count => 3, 
      :a => 1,
      :b => 1,
      :c => 1,
    }, a.calculate_values)
  end

  #
  # dependents
  #

  def test_dependents_automatically_update_with_attached_parents
    terms = %w{a0 a1 a2 a3 b0 b1 c0}
    a0, a1, a2, a3, b0, b1, c0 = terms.map {|name| Term.new(name) }

    assert_equal ['c0'], c0.dependents.map(&:name).sort

    c0.attach_parents(b0, b1)
    assert_equal ['b0', 'b1', 'c0'], c0.dependents.map(&:name).sort

    b0.attach_parents(a0, a1)
    assert_equal ['a0', 'a1', 'b0', 'b1', 'c0'], c0.dependents.map(&:name).sort

    b1.attach_parents(a2, a3)
    assert_equal ['a0', 'a1', 'a2', 'a3', 'b0', 'b1', 'c0'], c0.dependents.map(&:name).sort

    b0.detach_parents(a1)
    assert_equal ['a0', 'a2', 'a3', 'b0', 'b1', 'c0'], c0.dependents.map(&:name).sort

    c0.detach_parents(b1)
    assert_equal ['a0', 'b0', 'c0'], c0.dependents.map(&:name).sort
  end

  def test_dependents_automatically_updates_with_attached_children
    terms = %w{a0 a1 a2 a3 b0 b1 c0}
    a0, a1, a2, a3, b0, b1, c0 = terms.map {|name| Term.new(name) }

    assert_equal ['c0'], c0.dependents.map(&:name).sort

    b0.attach_children(c0)
    b1.attach_children(c0)
    assert_equal ['b0', 'b1', 'c0'], c0.dependents.map(&:name).sort

    a0.attach_children(b0)
    a1.attach_children(b0)
    assert_equal ['a0', 'a1', 'b0', 'b1', 'c0'], c0.dependents.map(&:name).sort

    a2.attach_children(b1)
    a3.attach_children(b1)
    assert_equal ['a0', 'a1', 'a2', 'a3', 'b0', 'b1', 'c0'], c0.dependents.map(&:name).sort

    a1.detach_children(b0)
    assert_equal ['a0', 'a2', 'a3', 'b0', 'b1', 'c0'], c0.dependents.map(&:name).sort

    b1.detach_children(c0)
    assert_equal ['a0', 'b0', 'c0'], c0.dependents.map(&:name).sort
  end

  #
  # values
  #

  def test_values_automatically_recalculate_with_attached_parents
    terms = %w{a0 b0 b1 c0 c1 c2 c3}
    a0, b0, b1, c0, c1, c2, c3 = terms.map do |name|
      Term.new(name) do |data, values|
        values[:count] = 1
      end
    end

    assert_equal 1, a0.values[:count]

    b0.attach_parents(a0)
    b1.attach_parents(a0)
    assert_equal 3, a0.values[:count]

    c0.attach_parents(b0)
    c1.attach_parents(b0)
    assert_equal 5, a0.values[:count]

    c2.attach_parents(b1)
    c3.attach_parents(b1)
    assert_equal 7, a0.values[:count]

    c1.detach_parents(b0)
    assert_equal 6, a0.values[:count]

    b1.detach_parents(a0)
    assert_equal 3, a0.values[:count]
  end

  def test_values_automatically_recalculate_with_attached_children
    terms = %w{a0 b0 b1 c0 c1 c2 c3}
    a0, b0, b1, c0, c1, c2, c3 = terms.map do |name|
      Term.new(name) do |data, values|
        values[:count] = 1
      end
    end

    assert_equal 1, a0.values[:count]

    a0.attach_children(b0, b1)
    assert_equal 3, a0.values[:count]

    b0.attach_children(c0, c1)
    assert_equal 5, a0.values[:count]

    b1.attach_children(c2, c3)
    assert_equal 7, a0.values[:count]

    b0.detach_children(c1)
    assert_equal 6, a0.values[:count]

    a0.detach_children(b1)
    assert_equal 3, a0.values[:count]
  end

  #
  # data=
  #

  def test_setting_data_recalculates_values_for_all_dependents
    a, b, c = %w{a b c}.map do |name|
      Term.new(name) do |data, values|
        values[:count] = data[:count] || 0
      end
    end

    a.attach_children(b)
    b.attach_children(c)

    assert_equal({:count => 0}, a.calculate_values)

    c.data = {:count => 1}
    assert_equal({:count => 1}, a.calculate_values)
    assert_equal({:count => 1}, b.calculate_values)
    assert_equal({:count => 1}, c.calculate_values)

    b.data = {:count => 1}
    assert_equal({:count => 2}, a.calculate_values)
    assert_equal({:count => 2}, b.calculate_values)
    assert_equal({:count => 1}, c.calculate_values)

    c.data = {:count => 2}
    assert_equal({:count => 3}, a.calculate_values)
    assert_equal({:count => 3}, b.calculate_values)
    assert_equal({:count => 2}, c.calculate_values)
  end
end

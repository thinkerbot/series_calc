#!/usr/bin/env ruby
require File.expand_path("../../helper", __FILE__)
require "series_calc/term"

class SeriesCalc::TermTest < Test::Unit::TestCase
  Term = SeriesCalc::Term

  #
  # attach_parents
  #

  def test_attach_parents_adds_child_to_parent_and_vice_versa
    parent, child = Term.new, Term.new
    child.attach_parents(parent)

    assert_equal [parent], child.parents
    assert_equal [child], parent.children
  end

  def test_attach_parents_raises_error_if_attached_to_self
    term = Term.new("term")
    err = assert_raises(RuntimeError) { term.attach_parents(term) }
    assert_equal 'cycle detected: "term" -> "term"', err.message
  end

  def test_attach_parents_raises_error_if_cycle_is_detected
    a, b, c = %w{a b c}.map {|identifier| Term.new(identifier) }

    c.attach_parents(b)
    b.attach_parents(a)

    err = assert_raises(RuntimeError) { a.attach_parents(c) }
    assert_equal 'cycle detected: "a" -> "c" -> "b" -> "a"', err.message
  end

  #
  # detach_parents
  #

  def test_detach_parents_removes_child_from_parent_and_vice_versa
    parent, child_a, child_b = Term.new, Term.new, Term.new
    child_a.attach_parents(parent)
    child_b.attach_parents(parent)

    assert_equal [parent], child_a.parents
    assert_equal [parent], child_b.parents
    assert_equal [child_a, child_b], parent.children

    child_b.detach_parents(parent)

    assert_equal [parent], child_a.parents
    assert_equal [], child_b.parents
    assert_equal [child_a], parent.children
  end

  #
  # attach_children
  #

  def test_attach_children_adds_parent_to_child_and_vice_versa
    parent, child = Term.new, Term.new
    parent.attach_children(child)

    assert_equal [child], parent.children
    assert_equal [parent], child.parents
  end

  def test_attach_children_raises_error_if_attached_to_self
    term = Term.new("term")
    err = assert_raises(RuntimeError) { term.attach_children(term) }
    assert_equal 'cycle detected: "term" -> "term"', err.message
  end

  def test_attach_children_raises_error_if_cycle_is_detected
    a, b, c = %w{a b c}.map {|identifier| Term.new(identifier) }

    a.attach_children(b)
    b.attach_children(c)

    err = assert_raises(RuntimeError) { c.attach_children(a) }
    assert_equal 'cycle detected: "c" -> "a" -> "b" -> "c"', err.message
  end

  #
  # detach_children
  #

  def test_detach_children_removes_parent_from_child_and_vice_versa
    parent_a, parent_b, child = Term.new, Term.new, Term.new
    parent_a.attach_children(child)
    parent_b.attach_children(child)

    assert_equal [child], parent_a.children
    assert_equal [child], parent_b.children
    assert_equal [parent_a, parent_b], child.parents

    parent_b.detach_children(child)

    assert_equal [child], parent_a.children
    assert_equal [], parent_b.children
    assert_equal [parent_a], child.parents
  end

  #
  # each_at_and_above
  #

  def test_each_at_and_above_yields_self_and_all_ancestors
    terms = %w{a0 a1 a2 a3 b0 b1 c0}
    a0, a1, a2, a3, b0, b1, c0 = terms.map {|identifier| Term.new(identifier) }

    c0.attach_parents(b0, b1)
    b0.attach_parents(a0, a1)
    b1.attach_parents(a2, a3)

    assert_equal %w{a0 a1 a2 a3 b0 b1 c0}, c0.each_at_and_above.map(&:identifier).sort
    assert_equal %w{a0 a1 b0}, b0.each_at_and_above.map(&:identifier).sort
    assert_equal %w{a0}, a0.each_at_and_above.map(&:identifier).sort
  end

  #
  # each_at_and_below
  #

  def test_each_at_and_below_yields_self_and_all_descendants
    terms = %w{a0 b0 b1 c0 c1 c2 c3}
    a0, b0, b1, c0, c1, c2, c3 = terms.map {|identifier| Term.new(identifier) }

    a0.attach_children(b0, b1)
    b0.attach_children(c0, c1)
    b1.attach_children(c2, c3)

    assert_equal %w{a0 b0 b1 c0 c1 c2 c3}, a0.each_at_and_below.map(&:identifier).sort
    assert_equal %w{b0 c0 c1}, b0.each_at_and_below.map(&:identifier).sort
    assert_equal %w{c0}, c0.each_at_and_below.map(&:identifier).sort
  end

  #
  # dependents
  #

  def test_dependents_automatically_update_with_attached_parents
    terms = %w{a0 a1 a2 a3 b0 b1 c0}
    a0, a1, a2, a3, b0, b1, c0 = terms.map {|identifier| Term.new(identifier) }

    assert_equal ['c0'], c0.dependents.map(&:identifier).sort

    c0.attach_parents(b0, b1)
    assert_equal ['b0', 'b1', 'c0'], c0.dependents.map(&:identifier).sort

    b0.attach_parents(a0, a1)
    assert_equal ['a0', 'a1', 'b0', 'b1', 'c0'], c0.dependents.map(&:identifier).sort

    b1.attach_parents(a2, a3)
    assert_equal ['a0', 'a1', 'a2', 'a3', 'b0', 'b1', 'c0'], c0.dependents.map(&:identifier).sort

    b0.detach_parents(a1)
    assert_equal ['a0', 'a2', 'a3', 'b0', 'b1', 'c0'], c0.dependents.map(&:identifier).sort

    c0.detach_parents(b1)
    assert_equal ['a0', 'b0', 'c0'], c0.dependents.map(&:identifier).sort
  end

  def test_dependents_automatically_updates_with_attached_children
    terms = %w{a0 a1 a2 a3 b0 b1 c0}
    a0, a1, a2, a3, b0, b1, c0 = terms.map {|identifier| Term.new(identifier) }

    assert_equal ['c0'], c0.dependents.map(&:identifier).sort

    b0.attach_children(c0)
    b1.attach_children(c0)
    assert_equal ['b0', 'b1', 'c0'], c0.dependents.map(&:identifier).sort

    a0.attach_children(b0)
    a1.attach_children(b0)
    assert_equal ['a0', 'a1', 'b0', 'b1', 'c0'], c0.dependents.map(&:identifier).sort

    a2.attach_children(b1)
    a3.attach_children(b1)
    assert_equal ['a0', 'a1', 'a2', 'a3', 'b0', 'b1', 'c0'], c0.dependents.map(&:identifier).sort

    a1.detach_children(b0)
    assert_equal ['a0', 'a2', 'a3', 'b0', 'b1', 'c0'], c0.dependents.map(&:identifier).sort

    b1.detach_children(c0)
    assert_equal ['a0', 'b0', 'c0'], c0.dependents.map(&:identifier).sort
  end

  #
  # value
  #

  class Count < Term
    def calculate_value
      value = 1
      children.each do |child|
        value += child.value
      end
      value
    end
  end

  def test_value_automatically_recalculates_with_attached_parents
    terms = %w{a0 b0 b1 c0 c1 c2 c3}
    a0, b0, b1, c0, c1, c2, c3 = terms.map {|identifier| Count.new(identifier) }

    assert_equal 1, a0.value

    b0.attach_parents(a0)
    b1.attach_parents(a0)
    assert_equal 3, a0.value

    c0.attach_parents(b0)
    c1.attach_parents(b0)
    assert_equal 5, a0.value

    c2.attach_parents(b1)
    c3.attach_parents(b1)
    assert_equal 7, a0.value

    c1.detach_parents(b0)
    assert_equal 6, a0.value

    b1.detach_parents(a0)
    assert_equal 3, a0.value
  end

  def test_value_automatically_recalculates_with_attached_children
    terms = %w{a0 b0 b1 c0 c1 c2 c3}
    a0, b0, b1, c0, c1, c2, c3 = terms.map {|identifier| Count.new(identifier) }

    assert_equal 1, a0.value

    a0.attach_children(b0, b1)
    assert_equal 3, a0.value

    b0.attach_children(c0, c1)
    assert_equal 5, a0.value

    b1.attach_children(c2, c3)
    assert_equal 7, a0.value

    b0.detach_children(c1)
    assert_equal 6, a0.value

    a0.detach_children(b1)
    assert_equal 3, a0.value
  end

  #
  # data=
  #

  class CountFromData < Term
    def calculate_value
      value = data ? data[:count] : 0
      children.each do |child|
        value += child.value
      end
      value
    end
  end

  def test_setting_data_recalculates_value_for_all_dependents
    a, b, c = %w{a b c}.map {|identifier| CountFromData.new(identifier) }

    a.attach_children(b)
    b.attach_children(c)

    assert_equal(0, a.value)

    c.data = {:count => 1}
    assert_equal(1, a.value)
    assert_equal(1, b.value)
    assert_equal(1, c.value)

    b.data = {:count => 1}
    assert_equal(2, a.value)
    assert_equal(2, b.value)
    assert_equal(1, c.value)

    c.data = {:count => 2}
    assert_equal(3, a.value)
    assert_equal(3, b.value)
    assert_equal(2, c.value)
  end
end
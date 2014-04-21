#!/usr/bin/env ruby
require File.expand_path("../../helper", __FILE__)
require "series_calc/term"

class SeriesCalc::TermTest < Test::Unit::TestCase
  Term = SeriesCalc::Term

  class Count < Term
    def calculate_value
      value = 1
      children.each do |child|
        value += child.value
      end
      value
    end
  end

  #
  # attach_parent
  #

  def test_attach_parent_adds_child_to_parent_and_vice_versa
    parent, child = Term.new, Term.new
    child.attach_parent(parent)

    assert_equal [parent], child.parents
    assert_equal [child], parent.children
  end

  def test_attach_parent_marks_new_parent_branch_to_recalculate_value
    terms = %w{a b c x y}.map {|identifier| Count.new(identifier) }
    a, b, c, x, y = terms

    c.attach_parent(b)
    b.attach_parent(a)
    y.attach_parent(x)

    terms.each {|term| term.value }
    assert_equal [false, false, false, false, false], terms.map(&:recalculate_value?)

    b.attach_parent(y)
    assert_equal [false, false, false, true, true], terms.map(&:recalculate_value?)
  end

  def test_attach_parent_marks_self_and_children_to_recalculate_dependents
    terms = %w{a b c x y}.map {|identifier| Count.new(identifier) }
    a, b, c, x, y = terms

    c.attach_parent(b)
    b.attach_parent(a)
    y.attach_parent(x)

    terms.each {|term| term.dependents }
    assert_equal [false, false, false, false, false], terms.map(&:recalculate_dependents?)

    b.attach_parent(y)
    assert_equal [false, true, true, false, false], terms.map(&:recalculate_dependents?)
  end

  def test_attach_parent_raises_error_if_attached_to_self
    term = Term.new("term")
    err = assert_raises(RuntimeError) { term.attach_parent(term) }
    assert_equal 'cycle detected: "term" -> "term"', err.message
  end

  def test_attach_parent_raises_error_if_cycle_is_detected
    a, b, c = %w{a b c}.map {|identifier| Term.new(identifier) }

    c.attach_parent(b)
    b.attach_parent(a)

    err = assert_raises(RuntimeError) { a.attach_parent(c) }
    assert_equal 'cycle detected: "a" -> "c" -> "b" -> "a"', err.message
  end

  #
  # detach_parent
  #

  def test_detach_parent_removes_child_from_parent_and_vice_versa
    parent, child_a, child_b = Term.new, Term.new, Term.new
    child_a.attach_parent(parent)
    child_b.attach_parent(parent)

    assert_equal [parent], child_a.parents
    assert_equal [parent], child_b.parents
    assert_equal [child_a, child_b], parent.children

    child_b.detach_parent(parent)

    assert_equal [parent], child_a.parents
    assert_equal [], child_b.parents
    assert_equal [child_a], parent.children
  end

  def test_detach_parent_marks_parent_branch_to_recalculate_value
    terms = %w{a b c x y}.map {|identifier| Count.new(identifier) }
    a, b, c, x, y = terms

    c.attach_parent(b)
    b.attach_parent(a)
    y.attach_parent(x)
    b.attach_parent(y)

    terms.each {|term| term.value }
    assert_equal [false, false, false, false, false], terms.map(&:recalculate_value?)

    b.detach_parent(y)
    assert_equal [false, false, false, true, true], terms.map(&:recalculate_value?)
  end

  def test_detach_parent_marks_self_and_children_to_recalculate_dependents
    terms = %w{a b c x y}.map {|identifier| Count.new(identifier) }
    a, b, c, x, y = terms

    c.attach_parent(b)
    b.attach_parent(a)
    y.attach_parent(x)
    b.attach_parent(y)

    terms.each {|term| term.dependents }
    assert_equal [false, false, false, false, false], terms.map(&:recalculate_dependents?)

    b.detach_parent(y)
    assert_equal [false, true, true, false, false], terms.map(&:recalculate_dependents?)
  end

  #
  # attach_child
  #

  def test_attach_child_adds_parent_to_child_and_vice_versa
    parent, child = Term.new, Term.new
    parent.attach_child(child)

    assert_equal [child], parent.children
    assert_equal [parent], child.parents
  end

  def test_attach_child_marks_self_and_parents_to_recalculate_value
    terms = %w{a b c x y}.map {|identifier| Count.new(identifier) }
    a, b, c, x, y = terms

    a.attach_child(b)
    b.attach_child(c)
    x.attach_child(y)

    terms.each {|term| term.value }
    assert_equal [false, false, false, false, false], terms.map(&:recalculate_value?)

    b.attach_child(x)
    assert_equal [true, true, false, false, false], terms.map(&:recalculate_value?)
  end

  def test_attach_child_marks_new_child_branch_to_recalculate_dependents
    terms = %w{a b c x y}.map {|identifier| Count.new(identifier) }
    a, b, c, x, y = terms

    a.attach_child(b)
    b.attach_child(c)
    x.attach_child(y)

    terms.each {|term| term.dependents }
    assert_equal [false, false, false, false, false], terms.map(&:recalculate_dependents?)

    b.attach_child(x)
    assert_equal [false, false, false, true, true], terms.map(&:recalculate_dependents?)
  end

  def test_attach_child_raises_error_if_attached_to_self
    term = Term.new("term")
    err = assert_raises(RuntimeError) { term.attach_child(term) }
    assert_equal 'cycle detected: "term" -> "term"', err.message
  end

  def test_attach_child_raises_error_if_cycle_is_detected
    a, b, c = %w{a b c}.map {|identifier| Term.new(identifier) }

    a.attach_child(b)
    b.attach_child(c)

    err = assert_raises(RuntimeError) { c.attach_child(a) }
    assert_equal 'cycle detected: "c" -> "a" -> "b" -> "c"', err.message
  end

  #
  # detach_child
  #

  def test_detach_child_removes_parent_from_child_and_vice_versa
    parent_a, parent_b, child = Term.new, Term.new, Term.new
    parent_a.attach_child(child)
    parent_b.attach_child(child)

    assert_equal [child], parent_a.children
    assert_equal [child], parent_b.children
    assert_equal [parent_a, parent_b], child.parents

    parent_b.detach_child(child)

    assert_equal [child], parent_a.children
    assert_equal [], parent_b.children
    assert_equal [parent_a], child.parents
  end

  def test_detach_child_marks_self_and_parents_to_recalculate_value
    terms = %w{a b c x y}.map {|identifier| Count.new(identifier) }
    a, b, c, x, y = terms

    a.attach_child(b)
    b.attach_child(c)
    x.attach_child(y)
    b.attach_child(x)

    terms.each {|term| term.value }
    assert_equal [false, false, false, false, false], terms.map(&:recalculate_value?)

    b.detach_child(x)
    assert_equal [true, true, false, false, false], terms.map(&:recalculate_value?)
  end

  def test_detach_child_marks_child_branch_to_recalculate_dependents
    terms = %w{a b c x y}.map {|identifier| Count.new(identifier) }
    a, b, c, x, y = terms

    a.attach_child(b)
    b.attach_child(c)
    x.attach_child(y)
    b.attach_child(x)

    terms.each {|term| term.dependents }
    assert_equal [false, false, false, false, false], terms.map(&:recalculate_dependents?)

    b.detach_child(x)
    assert_equal [false, false, false, true, true], terms.map(&:recalculate_dependents?)
  end

  #
  # dependents
  #

  def test_dependents_returns_unique_array_of_self_and_ancestors
    terms = %w{a0 a1 a2 a3 b0 b1 c0 d0}
    a0, a1, a2, a3, b0, b1, c0, d0 = terms.map {|identifier| Term.new(identifier) }

    a0.attach_child(b0)
    a1.attach_child(b0)
    a2.attach_child(b1)
    a3.attach_child(b1)

    b0.attach_child(c0)
    b1.attach_child(c0)

    c0.attach_child(d0)

    assert_equal ['a0', 'a1', 'a2', 'a3', 'b0', 'b1', 'c0'], c0.dependents.map(&:identifier).sort
  end

  def test_dependents_automatically_updates_with_attached_children
    terms = %w{a0 a1 a2 a3 b0 b1 c0}
    a0, a1, a2, a3, b0, b1, c0 = terms.map {|identifier| Term.new(identifier) }

    assert_equal ['c0'], c0.dependents.map(&:identifier).sort

    b0.attach_child(c0)
    b1.attach_child(c0)
    assert_equal ['b0', 'b1', 'c0'], c0.dependents.map(&:identifier).sort

    a0.attach_child(b0)
    a1.attach_child(b0)
    assert_equal ['a0', 'a1', 'b0', 'b1', 'c0'], c0.dependents.map(&:identifier).sort

    a2.attach_child(b1)
    a3.attach_child(b1)
    assert_equal ['a0', 'a1', 'a2', 'a3', 'b0', 'b1', 'c0'], c0.dependents.map(&:identifier).sort

    a1.detach_child(b0)
    assert_equal ['a0', 'a2', 'a3', 'b0', 'b1', 'c0'], c0.dependents.map(&:identifier).sort

    b1.detach_child(c0)
    assert_equal ['a0', 'b0', 'c0'], c0.dependents.map(&:identifier).sort
  end

  #
  # value
  #

  def test_value_automatically_recalculates_with_attached_parents
    terms = %w{a0 b0 b1 c0 c1 c2 c3}
    a0, b0, b1, c0, c1, c2, c3 = terms.map {|identifier| Count.new(identifier) }

    assert_equal 1, a0.value

    b0.attach_parent(a0)
    b1.attach_parent(a0)
    assert_equal 3, a0.value

    c0.attach_parent(b0)
    c1.attach_parent(b0)
    assert_equal 5, a0.value

    c2.attach_parent(b1)
    c3.attach_parent(b1)
    assert_equal 7, a0.value

    c1.detach_parent(b0)
    assert_equal 6, a0.value

    b1.detach_parent(a0)
    assert_equal 3, a0.value
  end

  def test_value_automatically_recalculates_with_attached_children
    terms = %w{a0 b0 b1 c0 c1 c2 c3}
    a0, b0, b1, c0, c1, c2, c3 = terms.map {|identifier| Count.new(identifier) }

    assert_equal 1, a0.value

    a0.attach_child(b0)
    a0.attach_child(b1)
    assert_equal 3, a0.value

    b0.attach_child(c0)
    b0.attach_child(c1)
    assert_equal 5, a0.value

    b1.attach_child(c2)
    b1.attach_child(c3)
    assert_equal 7, a0.value

    b0.detach_child(c1)
    assert_equal 6, a0.value

    a0.detach_child(b1)
    assert_equal 3, a0.value
  end

  #
  # set_data
  #

  class CountFromData < Term
    def calculate_value
      value = @data[:count] || 0
      children.each do |child|
        value += child.value
      end
      value
    end
  end

  def test_set_data_recalculates_value_for_all_dependents
    a, b, c = %w{a b c}.map {|identifier| CountFromData.new(identifier) }

    a.attach_child(b)
    b.attach_child(c)

    assert_equal(0, a.value)

    c.set_data(:count => 1)
    assert_equal(1, a.value)
    assert_equal(1, b.value)
    assert_equal(1, c.value)

    b.set_data(:count => 1)
    assert_equal(2, a.value)
    assert_equal(2, b.value)
    assert_equal(1, c.value)

    c.set_data(:count => 2)
    assert_equal(3, a.value)
    assert_equal(3, b.value)
    assert_equal(2, c.value)
  end

  class TermWithLinkages < CountFromData
    parent :a, 'one'
    child  :b, 'two'
  end

  def test_set_data_manages_linkages_via_terms
    t = TermWithLinkages.new('t')
    a, b = %w{a b}.map {|identifier| Term.new(identifier) }

    assert_equal nil, t.a
    assert_equal nil, t.b
    assert_equal [[], []], [t.parents, t.children]
    assert_equal [[], []], [a.parents, a.children]
    assert_equal [[], []], [b.parents, b.children]

    data  = {'one' => 'A', 'two' => 'B'}
    terms = {'A' => a, 'B' => b}
    t.set_data(data, terms)

    assert_equal a, t.a
    assert_equal b, t.b
    assert_equal [[a], [b]], [t.parents, t.children]
    assert_equal [[ ], [t]], [a.parents, a.children]
    assert_equal [[t], [ ]], [b.parents, b.children]

    data  = {'one' => 'B', 'two' => 'A'}
    terms = {'A' => a, 'B' => b}
    t.set_data(data, terms)

    assert_equal b, t.a
    assert_equal a, t.b
    assert_equal [[b], [a]], [t.parents, t.children]
    assert_equal [[t], [ ]], [a.parents, a.children]
    assert_equal [[ ], [t]], [b.parents, b.children]

    data  = {'one' => 'B', 'two' => 'A'}
    terms = {'A' => nil, 'B' => nil}
    t.set_data(data, terms)

    assert_equal nil, t.a
    assert_equal nil, t.b
    assert_equal [[], []], [t.parents, t.children]
    assert_equal [[], []], [a.parents, a.children]
    assert_equal [[], []], [b.parents, b.children]
  end

  def test_set_data_does_not_recalculate_if_only_a_parent_linkage_changes
    t, a = TermWithLinkages.new('term'), Term.new('parent')
    assert_equal 0, t.value

    assert_equal nil, t.a
    assert_equal false, t.recalculate_value?

    data  = {'one' => 'A'}
    terms = {'A' => a}
    t.set_data(data, terms)

    assert_equal a, t.a
    assert_equal false, t.recalculate_value?
  end
end
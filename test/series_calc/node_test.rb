#!/usr/bin/env ruby
require File.expand_path("../../helper", __FILE__)
require "series_calc/node"

class SeriesCalc::NodeTest < Test::Unit::TestCase
  Node = SeriesCalc::Node

  #
  # attach_parents
  #

  def test_attach_parents_adds_child_to_parent_and_vice_versa
    parent, child = Node.new, Node.new
    child.attach_parents(parent)

    assert_equal [parent], child.parents
    assert_equal [child], parent.children
  end

  def test_attach_parents_raises_error_if_attached_to_self
    node = Node.new("node")
    err = assert_raises(RuntimeError) { node.attach_parents(node) }
    assert_equal 'cycle detected: "node" -> "node"', err.message
  end

  def test_attach_parents_raises_error_if_cycle_is_detected
    a, b, c = %w{a b c}.map {|identifier| Node.new(identifier) }

    c.attach_parents(b)
    b.attach_parents(a)

    err = assert_raises(RuntimeError) { a.attach_parents(c) }
    assert_equal 'cycle detected: "a" -> "c" -> "b" -> "a"', err.message
  end

  #
  # detach_parents
  #

  def test_detach_parents_removes_child_from_parent_and_vice_versa
    parent, child_a, child_b = Node.new, Node.new, Node.new
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
    parent, child = Node.new, Node.new
    parent.attach_children(child)

    assert_equal [child], parent.children
    assert_equal [parent], child.parents
  end

  def test_attach_children_raises_error_if_attached_to_self
    node = Node.new("node")
    err = assert_raises(RuntimeError) { node.attach_children(node) }
    assert_equal 'cycle detected: "node" -> "node"', err.message
  end

  def test_attach_children_raises_error_if_cycle_is_detected
    a, b, c = %w{a b c}.map {|identifier| Node.new(identifier) }

    a.attach_children(b)
    b.attach_children(c)

    err = assert_raises(RuntimeError) { c.attach_children(a) }
    assert_equal 'cycle detected: "c" -> "a" -> "b" -> "c"', err.message
  end

  #
  # detach_children
  #

  def test_detach_children_removes_parent_from_child_and_vice_versa
    parent_a, parent_b, child = Node.new, Node.new, Node.new
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
    nodes = %w{a0 a1 a2 a3 b0 b1 c0}
    a0, a1, a2, a3, b0, b1, c0 = nodes.map {|identifier| Node.new(identifier) }

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
    nodes = %w{a0 b0 b1 c0 c1 c2 c3}
    a0, b0, b1, c0, c1, c2, c3 = nodes.map {|identifier| Node.new(identifier) }

    a0.attach_children(b0, b1)
    b0.attach_children(c0, c1)
    b1.attach_children(c2, c3)

    assert_equal %w{a0 b0 b1 c0 c1 c2 c3}, a0.each_at_and_below.map(&:identifier).sort
    assert_equal %w{b0 c0 c1}, b0.each_at_and_below.map(&:identifier).sort
    assert_equal %w{c0}, c0.each_at_and_below.map(&:identifier).sort
  end
end

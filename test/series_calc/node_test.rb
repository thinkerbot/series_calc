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

  def test_attach_parents_raises_error_when_a_cycle_is_detected
    node = Node.new "node"
    err = assert_raises(RuntimeError) { node.attach_parents(node) }
    assert_equal 'cannot attach parents: ["node"] (cycle detected)', err.message
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

  def test_attach_children_raises_error_when_a_cycle_is_detected
    node = Node.new "node"
    err = assert_raises(RuntimeError) { node.attach_children(node) }
    assert_equal 'cannot attach children: ["node"] (cycle detected)', err.message
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
  # ancestors
  #

  def test_ancestors_yields_all_ancestors_of_node
    ancestors = %w{a0 a1 a2 a3 b0 b1}
    a0, a1, a2, a3, b0, b1, c0 = ancestors.map {|name| Node.new(name) }
    c0 = Node.new('c0')

    c0.attach_parents(b0, b1)
    b0.attach_parents(a0, a1)
    b1.attach_parents(a2, a3)

    assert_equal ancestors, c0.ancestors.to_a.map(&:name).sort
  end

  #
  # descendants
  #

  def test_descendants_yields_all_descendants_of_node
    descendants = %w{b0 b1 c0 c1 c2 c3}
    a0 = Node.new('a0')
    b0, b1, c0, c1, c2, c3 = descendants.map {|name| Node.new(name) }

    a0.attach_children(b0, b1)
    b0.attach_children(c0, c1)
    b1.attach_children(c2, c3)

    assert_equal descendants, a0.descendants.to_a.map(&:name).sort
  end
end

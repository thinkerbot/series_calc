#!/usr/bin/env ruby
require File.expand_path('../../helper', __FILE__)
require 'series_calc/controller'

class SeriesCalc::ControllerTest < Test::Unit::TestCase
  Controller = SeriesCalc::Controller
  Dimension  = SeriesCalc::Dimension
  Timeframe  = SeriesCalc::Timeframe

  attr_reader :now

  def setup
    @now = Time.zone.now
  end

  def timeseries
    @timeseries ||= Timeseries.create(
      :start_time => '2010-01-01',
      :n_steps => 5,
      :period => '15m',
    )
  end

  def timeframe
    @timeframe ||= Timeframe.new(timeseries)
  end

  class SumTerm < SeriesCalc::Term
    def calculate_value
      value = @data[:value] || 0
      children.each do |child|
        value += child.value
      end
      value
    end
  end

  class NegativeSumTerm < SeriesCalc::Term
    def calculate_value
      value = -1 * (@data[:value] || 0)
      children.each do |child|
        value -= child.value
      end
      value
    end
  end

  #
  # term_class_for
  #

  def test_dimension_for_returns_term_class_for_id
    controller = Controller.new(timeframe, {
      'a' => SumTerm,
      'b' => NegativeSumTerm,
    })
    assert_equal SumTerm, controller.term_class_for('a/one')
    assert_equal NegativeSumTerm, controller.term_class_for('b/one')
  end

  #
  # dimension_for
  #

  def test_dimension_for_creates_new_dimension_and_initializes_terms_in_each_slot
    controller = Controller.new(timeframe, {'a' => SumTerm})
    dimension  = controller.dimension_for('a/one')
    assert_equal Dimension, dimension.class
    assert_equal dimension, controller.dimension_for('a/one')

    terms = timeframe.slots.map {|slot| slot['a/one'] }
    assert_equal [
      ['a/one@0', SumTerm],
      ['a/one@1', SumTerm],
      ['a/one@2', SumTerm],
      ['a/one@3', SumTerm],
      ['a/one@4', SumTerm],
    ], terms.map {|term| [term.id, term.class] }
    
  end

  def test_dimension_for_raises_error_for_unregistered_type
    controller = Controller.new(timeframe)
    err = assert_raises(RuntimeError) { controller.dimension_for('unknown/one') }
    assert_equal 'unknown dimension: "unknown"', err.message
  end
end

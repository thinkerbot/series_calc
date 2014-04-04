#!/usr/bin/env ruby
require File.expand_path("../../helper", __FILE__)
require "series_calc/term"

class Count < SeriesCalc::Term
  def calculate_value
    value = data ? data[:offset] : 1
    children.each do |child|
      value += child.value
    end
    value
  end
end

Benchmark.bm(35) do |bm|
  n = 100
  nk = n * 1000
  tries = 3

  x = 10
  y = 100
  z = 10
  m = (x * y * z) / 1000

  head = Count.new('head')
  tail = Count.new('tail')
  hc = x.times.map do |xi|
    xn = Count.new("#{xi}")
    xc = y.times.map do |yi|
      yn = Count.new("#{xi}-#{yi}")
      yc = z.times.map do |zi|
        Count.new("#{xi}-#{yi}-#{zi}").attach_children(tail)
      end
      yn.attach_children(*yc)
    end
    xn.attach_children(*xc)
  end
  head.attach_children(*hc)

  tries.times do |try|
    bm.report("#{n} #{m}k-tree data (#{try})") do
      n.times do |i|
        tail.data = {:offset => i}
      end
    end
  end

  tries.times do |try|
    bm.report("#{n} #{m}k-tree data+value (#{try})") do
      n.times do |i|
        tail.data = {:offset => i}
        head.value
      end
    end
  end
end

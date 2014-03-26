#!/usr/bin/env ruby
require File.expand_path("../../helper", __FILE__)
require "series_calc/term"

class ZeroTerm < SeriesCalc::Term
  def calculate_value
    0
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

  head = ZeroTerm.new
  tail = ZeroTerm.new
  hc = x.times.map do |xi|
    xn = ZeroTerm.new("#{xi}")
    xc = y.times.map do |yi|
      yn = ZeroTerm.new("#{xi}-#{yi}")
      yc = z.times.map do |zi|
        ZeroTerm.new("#{xi}-#{yi}-#{zi}").attach_children(tail)
      end
      yn.attach_children(*yc)
    end
    xn.attach_children(*xc)
  end
  head.attach_children(*hc)

  tries.times do |try|
    bm.report("#{n} #{m}k-tree mark (#{try})") do
      n.times do
        tail.dependents.each(&:recalculate_value)
      end
    end
  end

  tries.times do |try|
    bm.report("#{n} #{m}k-tree mark+value (#{try})") do
      n.times do
        tail.dependents.each(&:recalculate_value)
        head.value
      end
    end
  end
end

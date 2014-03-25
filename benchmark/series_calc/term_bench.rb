#!/usr/bin/env ruby
require File.expand_path("../../helper", __FILE__)
require "series_calc/term"

Benchmark.bm(35) do |bm|
  n = 100
  nk = n * 1000
  tries = 3

  x = 10
  y = 100
  z = 10
  m = (x * y * z)

  t = SeriesCalc::Term.new
  tc = x.times.map do |xi|
    xn = SeriesCalc::Term.new("#{xi}")
    xc = y.times.map do |yi|
      yn = SeriesCalc::Term.new("#{xi}-#{yi}")
      yc = z.times.map do |zi|
        SeriesCalc::Term.new("#{xi}-#{yi}-#{zi}")
      end
      yn.attach_children(*yc)
    end
    xn.attach_children(*xc)
  end
  t.attach_children(*tc)

  tries.times do |try|
    bm.report("#{n}k #{m}-tree calculate_values (#{try})") do
      nk.times { t.calculate_values }
    end
  end
end

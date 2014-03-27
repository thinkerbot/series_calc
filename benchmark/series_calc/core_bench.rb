#!/usr/bin/env ruby
require File.expand_path("../../helper", __FILE__)

Benchmark.bm(35) do |bm|
  n = 100
  nk = n * 1000
  tries = 3

  m = 11
  mk = m * 1000
  array = Array.new(mk)

  tries.times do |try|
    bm.report("#{n} #{m}k-array#each (#{try})") do
      n.times do
        array.each(&:object_id)
      end
    end
  end
end

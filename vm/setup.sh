#!/bin/bash
sudo apt-get update
sudo apt-get -y install openjdk-7-jdk unzip jruby vim

jruby --fast -Ilib -J-Xmx3000m ./benchmark/series_calc/term_bench.rb

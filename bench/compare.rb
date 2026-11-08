#!/usr/bin/env ruby
# Prints a before/after table from two saved runs:  ruby bench/compare.rb before after
require "json"

before_label, after_label = ARGV
abort "usage: ruby bench/compare.rb BEFORE_LABEL AFTER_LABEL" unless before_label && after_label

load_run = ->(label) { JSON.parse(File.read(File.expand_path("results/#{label}.json", __dir__))).to_h { |r| [r["endpoint"], r] } }
before = load_run.call(before_label)
after = load_run.call(after_label)

puts format("%-20s %14s %14s %12s %9s", "endpoint", "p95 before", "p95 after", "improvement", "speedup")
before.each do |name, b|
  a = after[name] or next
  gain = (1 - a["p95_ms"] / b["p95_ms"]) * 100
  puts format("%-20s %11.1f ms %11.1f ms %11.1f%% %8.1fx", name, b["p95_ms"], a["p95_ms"], gain, b["p95_ms"] / a["p95_ms"])
end

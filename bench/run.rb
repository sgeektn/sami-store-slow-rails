#!/usr/bin/env ruby
# Dependency-free benchmark: hits each endpoint one request at a time and reports latency.
#
#   ruby bench/run.rb --label before            # against http://localhost:3000
#   ruby bench/run.rb --label after --base http://localhost:3001
#   ruby bench/compare.rb before after          # side-by-side table
#
require "net/http"
require "json"
require "optparse"
require "uri"

opts = { base: "http://localhost:3000", label: "run", scale: 1.0 }
OptionParser.new do |o|
  o.on("--base URL", "App URL (default #{opts[:base]})") { |v| opts[:base] = v }
  o.on("--label NAME", "Result name, saved to bench/results/NAME.json") { |v| opts[:label] = v }
  o.on("--scale X", Float, "Multiply the number of requests (default 1)") { |v| opts[:scale] = v }
end.parse!

CUSTOMERS = 20_000 # matches the seed
ENDPOINTS = [
  { name: "GET /products",       requests: 50,  warmup: 3,
    build: ->(_) { Net::HTTP::Get.new("/products") } },
  { name: "GET /orders?email=",  requests: 100, warmup: 3,
    build: ->(_) { Net::HTTP::Get.new("/orders?email=customer#{rand(1..CUSTOMERS)}@example.com") } },
  { name: "GET /api/products",   requests: 30,  warmup: 2,
    build: ->(_) { Net::HTTP::Get.new("/api/products") } },
  { name: "POST /checkout",      requests: 15,  warmup: 1,
    build: ->(_) {
      Net::HTTP::Post.new("/checkout").tap do |r|
        r.set_form_data("email" => "customer#{rand(1..CUSTOMERS)}@example.com", "product_id" => rand(1..50_000), "quantity" => 1)
      end
    } }
].freeze

def percentile(sorted_ms, p)
  sorted_ms[[(p / 100.0 * sorted_ms.size).ceil - 1, 0].max]
end

uri = URI(opts[:base])
http = Net::HTTP.new(uri.host, uri.port)
http.read_timeout = 60
http.start

results = ENDPOINTS.map do |ep|
  one = lambda do
    req = ep[:build].call(nil)
    t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    res = http.request(req)
    ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t) * 1000
    abort "#{ep[:name]} answered #{res.code}" unless res.code.start_with?("2")
    ms
  end

  ep[:warmup].times { one.call }
  times = Array.new((ep[:requests] * opts[:scale]).ceil) { one.call }.sort
  row = { "endpoint" => ep[:name], "requests" => times.size,
          "p50_ms" => percentile(times, 50).round(1), "p95_ms" => percentile(times, 95).round(1),
          "max_ms" => times.last.round(1) }
  puts format("%-20s n=%-4d p50=%8.1f ms   p95=%8.1f ms   max=%8.1f ms",
              row["endpoint"], row["requests"], row["p50_ms"], row["p95_ms"], row["max_ms"])
  row
end

path = File.expand_path("results/#{opts[:label]}.json", __dir__)
File.write(path, JSON.pretty_generate(results))
puts "Saved #{path}"

#!/usr/bin/env ruby
#
# Calculates statistics about new casts from any passed JSON files.
#

require 'json'

casts = []
ARGV.each do |fn|
    next unless File.exists?(fn)
    cfg = JSON.parse(IO.read(fn))
    if cfg.has_key?("craft_attrs") and cfg["craft_attrs"].has_key?("new_casts") then
        casts << cfg["craft_attrs"]["new_casts"].to_i
    end
end

casts.sort!
count = casts.size
sum = casts.inject(:+)
min = casts.inject { |m,x| m < x ? m : x }
max = casts.inject { |m,x| m > x ? m : x }
mean = sum.to_f / count.to_f
median = casts[casts.size/2]
stddev = Math.sqrt(casts.map {|x| (x-mean).to_f ** 2}.inject(:+) / (count-1).to_f)

puts "Configs: #{count}"
puts "Min:     #{min}"
puts "Max:     #{max}"
puts "Mean:    #{mean}"
puts "Median:  #{median}"
puts "Stddev:  #{stddev}"

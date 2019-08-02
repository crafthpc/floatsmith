#!/usr/bin/env ruby
#
# Calculates statistics about labels from any passed JSON files.
#

require 'json'

label_types  = {}   # label prefix => number of unique labels with that prefix
label_counts = {}   # label count => number of actions with that many labels
label_vars   = {}   # label name => list of variables with that label

next_gid = 1

ARGV.each do |fn|
    next unless File.exists?(fn)
    cfg = JSON.parse(IO.read(fn))
    next unless cfg.has_key?("actions")
    cfg["actions"].each do |a|
        next unless a.has_key?("labels")
        labels = a["labels"]
        label_counts[labels.size] = 0 unless label_counts.has_key?(labels.size)
        label_counts[labels.size] += 1
        labels.each do |lbl|
            type = lbl[/^[^=]*/]
            label_types[type] = [] unless label_types.has_key?(type)
            label_types[type] << lbl unless label_types[type].include?(lbl)
            label_vars[lbl] = [] unless label_vars.has_key?(lbl)
            if a.has_key?("name") then
                label_vars[lbl] << a["name"]
            else
                label_vars[lbl] << a["handle"]
            end
        end
    end
end

puts
puts "Label types:"
label_types.each  { |k,v| puts "  #{k}: #{v.size} labels" }
puts
puts "Label counts:"
label_counts.keys.sort.each { |k| puts "  #{k} labels: #{label_counts[k]} actions" }
label_types.keys.each do |lbl|
    label_counts = {}
    puts
    puts "Labels (#{lbl}):"
    label_vars.each do |k,v|
        label_counts[v.size] = 0 unless label_counts.has_key?(v.size)
        label_counts[v.size] += 1
        puts "  #{k}: #{v.size} actions" if k.start_with?(lbl)
    end
    puts "Counts:"
    label_counts.keys.sort.each { |k| puts "  #{k} actions: #{label_counts[k]} labels" }
end
puts


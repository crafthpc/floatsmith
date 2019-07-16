#!/usr/bin/env ruby
#
# Calculates statistics about labels from any passed JSON files.
#

require 'json'

label_counts = {}   # label count => number of actions with that many labels
label_vars   = {}   # label name => list of variables with that label
label_groups = {}   # label name => group id
groups       = {}   # group id => list of variables in that group

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
        gid = nil
        labels.each do |lbl|
            label_vars[lbl] = [] unless label_vars.has_key?(lbl)
            if a.has_key?("name") then
                label_vars[lbl] << a["name"]
            else
                label_vars[lbl] << a["handle"]
            end
            gid = label_groups[lbl] if label_groups.has_key?(lbl)
        end
        if gid.nil? then
            gid = next_gid
            next_gid += 1
            groups[gid] = []
        end
        labels.each do |lbl|
            label_groups[lbl] = gid
        end
        if a.has_key?("name") then
            groups[gid] << a["name"]
        else
            groups[gid] << a["handle"]
        end
    end
end

puts "Label counts:"
label_counts.each { |k,v| puts "#{k} labels: #{v} actions" }
puts "Labels:"
label_vars.each   { |k,v| puts "#{v.size} #{k}: #{v.to_s}" }
puts "Groups (size > 1):"
groups.each       { |k,v| puts "Group #{k}: #{v.to_s}" unless v.size < 2 }


#!/usr/bin/env ruby
#
# Extract all actions with a particular label as a new config
#

require 'json'

if ARGV.size < 2 then
    puts "Usage: extract_label_cfg.rb <label> <json-files>"
    exit
end
label = ARGV.shift

new_cfg = {}
new_cfg["tool_id"] = "FloatSmith"
new_cfg["version"] = "1"
new_cfg["actions"] = []

ARGV.each do |fn|
    next unless File.exists?(fn)
    cfg = JSON.parse(IO.read(fn))
    next unless cfg.has_key?("actions")
    cfg["actions"].each do |a|
        next unless a.has_key?("labels")
        new_cfg["actions"] << a if a["labels"].include?(label)
    end
end

puts JSON.pretty_generate(new_cfg)


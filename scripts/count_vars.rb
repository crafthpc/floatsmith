#!/usr/bin/env ruby
#
# Counts replaced variables from any passed JSON files.
#

require 'json'

ARGV.each do |fn|
    next unless File.exists?(fn)
    cfg = JSON.parse(IO.read(fn))
    vars = 0
    cfg["actions"].each do |a|
        vars +=1 if a.has_key?("action") and a["action"] == "change_var_basetype"
    end
    if cfg.has_key?("craft_attrs") and cfg["craft_attrs"].has_key?("new_casts") then
        puts "#{vars} #{cfg["craft_attrs"]["new_casts"].to_s} #{fn}"
    else
        puts "#{vars} #{fn}"
    end
end

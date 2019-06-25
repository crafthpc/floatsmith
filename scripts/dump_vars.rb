#!/usr/bin/env ruby
#
# Dumps replaced variables from any passed JSON files.
#

require 'json'

ARGV.each do |fn|
    next unless File.exists?(fn)
    cfg = JSON.parse(IO.read(fn))
    next unless cfg.has_key?("actions")
    cfg["actions"].each do |a|
        next unless a.has_key?("action") and a["action"] == "change_var_basetype"
        print "#{a["name"]}"
        print " #{a["scope"]}" if a.has_key?("scope")
        print " #{a["source_info"][/[^\/]*$/]}" if a.has_key?("source_info")
        puts ""
    end
end

#!/usr/bin/env ruby
#
# Merges multiple JSON configurations by taking the union of all replacements.
#

require 'json'
require 'set'

config = {}
config["version"] = "1"
config["tool_id"] = "FloatSmith"
config["actions"] = []

uids = Set.new
ARGV.each do |fn|
    next unless File.exists?(fn)
    cfg = JSON.parse(IO.read(fn))
    next unless cfg.has_key?("actions")
    cfg["actions"].each do |a|
        if a.has_key?("action") and a["action"] == "change_var_basetype" and
                a.has_key?("to_type") and a["to_type"] == "float" and
                a.has_key?("uid") then
            if not uids.include?(a["uid"]) then
                config["actions"] << a
                uids << a["uid"]
            end
        end
    end
end

# sort actions by uid
config["actions"].sort! { |a,b| a["uid"].to_i <=> b["uid"].to_i }

puts JSON.pretty_generate(config)

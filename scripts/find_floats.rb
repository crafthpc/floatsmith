#!/usr/bin/env ruby
#
# Script for finding and comparing floating point numbers between two outputs
#

# Needed to store very large and very accurate floats
require 'bigdecimal'

# Needed to parse command line options
require 'optparse'


# Supported modes: All, Avg, Min, Max
mode = :All

# False for absolute error, True for relative error
relative = false

# Only print out pass or fail message (if threshold provided), no error information
quiet = false

# Compare error against threshold using specified mode, and print pass/fail message
use_threshold = false
threshold = BigDecimal.new(0)


# Parser for command line options
parser = OptionParser.new do|opts|
    opts.banner = "Usage: find_floats.rb -[ahqrt] <original> <compare>"

    opts.on("-tTHRESHOLD", "--threshold=THRESHOLD", "Provide a threshold " \
            "(exclusive) to be compared against") do |t|
        use_threshold = true
        threshold = BigDecimal.new(t)
    end

    opts.on("--min", "Compare only the minimum of all errors in the output") do
        mode = :Min
    end

    opts.on("--max", "Compare only the maximum of all errors in the output") do
        mode = :Max
    end

    opts.on("--avg", "Compare the average of all errors in the output") do
        mode = :Avg
    end

    opts.on("--all", "Compare all errors in the output (Default)") do
        mode = :All
    end

    opts.on("-r", "--relative", "Run with relative error") do 
        relative = true
    end

    opts.on("-a", "--absolute", "Run with absolute error (Default)") do 
        relative = false
    end

    opts.on("-q", "--quiet", "Run in quiet mode, only output pass or fail message") do 
        quiet = true
    end

    opts.on('-h', '--help', 'Displays Help') do
        puts opts
        exit
    end

end

# Parse the command line options
parser.parse!

# Ensure we were provided 2 files
if ARGV.length != 2
    puts parser.help
    exit
end

orig = Array.new
comp = Array.new

# Read in floats from the origional file
File.open(ARGV[0]).each_line do |line|
    line.scan(/([-+]?[0-9]+\.[0-9]+)[eE]?([-+]?[0-9]+)?/).each do |match|
        num = BigDecimal.new(match.first)
        if match.last != nil
            num *= BigDecimal.new("10")**BigDecimal.new(match.last)
        end
        orig.push num
    end
end

# Read in floats from the camparison file
File.open(ARGV[1]).each_line do |line|
    line.scan(/([-+]?[0-9]+\.[0-9]+)[eE]?([-+]?[0-9]+)?/).each do |match|
        num = BigDecimal.new(match.first)
        if match.last != nil
            num *= BigDecimal.new("10")**BigDecimal.new(match.last)
        end
        comp.push num
    end
end

# If we cannot match all floats in both files up
# This could be an issue in the regex
if orig.length != comp.length
    puts "The input files did not match, please check the format and try again."
    exit
end

# Start with the min/max as the first floats error
if mode == :Min || mode == :Max
    total_error = (orig[0] - comp[0]).abs
elsif
    total_error = BigDecimal.new(0)
end

# Needed to index into comp array
i = 0

passed = true

# Compare all numbers in both files against each other
# Calculate error based on the mode
orig.each do |num|
    error = (num - comp[i]).abs

    # If in relative mode, calculate the relative error
    if relative
        error = error/num
    end

    # 
    case mode
    when :All
    
        if use_threshold && error > threshold
            passed = false
        end

        # Always print unless: (1) we were given a threshold and we are within it
        #                      (2) we are in quiet mode
        if (!use_threshold || error > threshold) && !quiet
            printf("orig: %.7E\tnew: %.7E\terror: %.7E\n", num, comp[i], error)
        end

    when :Min

        if error < total_error
            total_error = error
        end

    when :Max

        if error > total_error
            total_error = error
        end

    when :Avg

            total_error += error

    else 
        puts "Unsupported mode #{mode}"
        puts "supperted modes are: All, Avg, Min, Max"
        exit
    end
    i += 1
end

# If we are in average mode then calculate the average
if mode == :Avg
    total_error = total_error / orig.length
end

# Based on the mode print out min max or average error
if mode == :Min || mode == :Max || mode == :Avg
    if !quiet
        printf("%s error: %.7E\n", mode.to_s, total_error)
    end

    if use_threshold && (total_error > threshold)
            passed = false
    end
end

# If a threshold was provided, print out pass or fail status
if use_threshold 
    if passed
        puts "status:  pass"
    else
        puts "status:  fail"
    end
end 

#!/usr/bin/env ruby
#
# Script for finding and comparing floating point numbers in an output

require 'bigdecimal'
require 'optparse'

verbose = false;
relative = false;

parser = OptionParser.new do|opts|
  opts.banner = "Usage: find_floats.rb -[vrh] <original> <compare> <threshold>"

  opts.on("-v", "--verbose", "Run verbosely") do 
    verbose = true
  end

  opts.on("-r", "--relative", "Run with relative error instead of absolute") do 
    relative = true
  end

  opts.on('-h', '--help', 'Displays Help') do
    puts opts
    exit
  end

end

parser.parse!

if ARGV.length != 3
  puts  "Usage: find_floats.rb -[vrh] <original> <compare> <threshold>"
  exit
end

orig = Array.new
comp = Array.new

threshold = BigDecimal.new(ARGV[2]);

File.open(ARGV[0]).each_line do |line|
  line.scan(/([-+]?[0-9]+\.[0-9]+)[eE]?([-+]?[0-9]+)?/).each do |match|
    num = BigDecimal.new(match.first)
    if (match.last != nil)
#       num *= BigDecimal(10**match.last.to_i)
      num *= BigDecimal.new("10")**BigDecimal.new(match.last)
    end
    orig.push num
  end
end

File.open(ARGV[1]).each_line do |line|
  line.scan(/([-+]?[0-9]+\.[0-9]+)[eE]?([-+]?[0-9]+)?/).each do |match|
    num = BigDecimal.new(match.first)
    if (match.last != nil)
#       num *= BigDecimal.new(10**match.last.to_i)
      num *= BigDecimal.new("10")**BigDecimal.new(match.last)
    end
    comp.push num
  end
end

i = 0;
passed = true;
orig.each do |num|
  error = (num - comp[i]).abs
  if relative
    error = error/num
  end

  if error >= threshold
    passed = false
  end

  if verbose || error >= threshold
    printf("orig: %.7E\tnew: %.7E\terror: %.7E\n", num, comp[i], error)
  end
  i += 1 
end

if passed
  puts "PASS"
elsif
  puts "FAIL"
end

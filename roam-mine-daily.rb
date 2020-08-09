#!/usr/bin/env ruby

require 'json'
require 'date'
require 'pry_debug'
require 'optparse'

# Does the page have a "Roam day-like" title?
def is_day_page?(page)
  page["title"] =~ /^(#{Date::MONTHNAMES[1..-1].join('|')}).*, \d{4}/
end

# pattern - the pattern to match (String or Regexp)
# string - the string to check for match
def string_matches_pattern(pattern, string)
  case pattern
  when Regexp
     pattern === node['string']
  when String
    string.include?(pattern)
  end
end

# Recursively (breadth-first) find the first block reference for a node
# that matches the pattern.
# pattern - can === a string
# nodes - a list of things that have a 'uid', and maybe a 'children'
def nested_block_reference_matching_pattern(pattern, nodes)
  return nil if nodes.nil? || nodes.empty?

  matching = nodes.find {|node|
    string_matches_pattern(pattern, node['string'])
  }

  return matching['uid'] if matching

  nodes.inject(nil) {|r, node|
    r || nested_block_reference_matching_pattern(pattern, node['children'] || [])
  }
end

# Given the pages
def get_matching_for_pages(pattern, pages)
  pages.map {|page|
    uid = nested_block_reference_matching_pattern(pattern, page['children'] || [])
    uid ?
      [ page['title'], uid ] :
      nil
  }.compact
end

def month_for_date(date_string)
  date = Date.parse(date_string)
  "#{Date::MONTHNAMES[date.month]}, #{date.year}"
end

# [page] => {"month page": [page]}
def group_by_month(day_pages)
  day_pages.inject({}) {|h, page|
    month_string = month_for_date(page['title'])
    h[month_string] ||= []
    h[month_string] << page
    h
  }
end

# Given an Enumerable of pages, find the ones that are day pages.
def get_day_pages(pages)
  pages.select(&method(:is_day_page?))
end

# Parse the IO as a single JSON doc.
def parse(stream)
  pages = JSON.load(stream)
end

# Given the arguments, return the stream to parse.
# options - Configuration based on command line arguments
def get_stream(options)
  options[:file].nil? ?
    $stdin :
    open(File.expand_path(options[:file]))
end

# Return a hash of { month_name: [page] }
def process(pattern, pages)
  day_pages = get_day_pages(pages)
  by_month = group_by_month(day_pages)
  by_month.map {|month, pages|
    matching = get_matching_for_pages(pattern, pages)
    next nil if matching.empty?

    matching = matching.sort_by {|d, e| Date.parse(d)}
    [month, matching]
  }.compact.sort_by {|month, _|
    Date.parse(month)
  }.to_h
end

# Format the list of pages for Roam, nested under the pattern.
#
# title - The pattern to render as the top-level node
# pages - The list of day, uid to format
# E.g.
# [[Journal]]
#   [[August 1st, 2020]]
#     ((abcdefghi))
#   [[August 6th, 2020]]
#     ((bcdefghij))
def format(title, pages)
  return nil if pages.nil?
  formatted_pages = pages.map {|day, uid|
    (<<-OUTPUT).chomp
  [[#{day}]]
    {{embed: ((#{uid}))}}
    OUTPUT
  }.join("\n")
  <<-OUTPUT
#{title}
#{formatted_pages}
  OUTPUT
end

def filter_months(match_month, results_by_month)
  return results_by_month if match_month.nil?

  results_by_month.select {|month, _|
    month == match_month
  }
end

# Is the configuration built from the command line args valid?
def config_valid?(config)
  !config[:pattern].nil?
end

# Return a configuration based on the command line arguments.
def parse_arguments!(argv)
  results = {}

  option_parser = OptionParser.new do |opts|
    opts.on("-h", "--help", "Prints this help") do
      results[:help] = opts.help
    end

    opts.on("-sS", "--match-string=S", "Match nodes containing the string") do |s|
      results[:pattern] = s
    end

    opts.on("-mD", "--month=D", "Only return results for the month containing the given date") do |d|
      results[:month] = month_for_date(d)
    end

    opts.on("-fF", "--file=F", "Use the given file as input. If absent, will parse STDIN") do |f|
      results[:file] = f
    end
  end

  option_parser.parse!(argv)
  if argv.count != 0 || !config_valid?(results)
    results = { :help => option_parser.help }
  end

  results
end

if __FILE__ == $0
  options = parse_arguments!(ARGV)

  if options[:help]
    puts options[:help]
    exit(1)
  end

  stream = get_stream(options)
  pages = parse(stream)
  results_by_month = process(options[:pattern], pages)
  relevant_results = filter_months(options[:month], results_by_month)
  formatted = relevant_results.map {|month, results|
    format(options[:pattern], results)
  }.join("\n\n")
  puts formatted
end

require 'set'
require 'date'
require_relative 'roam_date'

class RoamCalendar
  def self.nil_pad_dates_by_weeks(dates)
    dates = dates.sort
    first = RoamDate.sunday_on_or_before_date(dates.first)
    last = RoamDate.saturday_on_or_after_date(dates.last)
    date_set = Set.new(dates)
    (first..last).map {|date|
      date_set.include?(date) ? date : nil
    }
  end

  def self.string_node(string)
    {
      "string" => string,
      "children" => []
    }
  end

  def self.roam_calendar(dates)
    dates = nil_pad_dates_by_weeks(dates)
    weeks = dates.each_slice(7)
    table = string_node("{{table}}")
    (0..6).inject(table) do |n, i|
      sn = string_node("**#{Date::ABBR_DAYNAMES[i]}**")
      n["children"] << sn
      sn
    end

    weeks.each do |week|
      week.inject(table) do |n, date|
        sn = date.nil? ?
          string_node("") :
          string_node(RoamDate.roam_date_link(date, "#{date.mday}"))
        n["children"] << sn
        sn
      end
    end

    table
  end

  def self.month_range_containing_date(date)
    first = Date.new(date.year, date.month, 1)
    last = first.next_month - 1
    (first..last)
  end
end

require 'date'

module RoamDate
  extend self

  def roam_date_link(date, label_text=nil)
    return "" if date.nil?

    date_text = "[[#{roam_date(date)}]]"
    return date_text if label_text.nil?

    "[#{label_text}](#{date_text})"
  end

  def roam_date(date)
    return "" if date.nil?

    "#{Date::MONTHNAMES[date.month]} #{ordinal(date.mday)}, #{date.year}"
  end

  def ordinal(n)
    "#{n}#{ordinal_part(n)}"
  end

  # Lifted from: https://stackoverflow.com/questions/37364637/trying-to-convert-and-display-an-ordinal-number#37364719
  def ordinal_part(n)
    last_number = n % 10
    if [11,12,13].include?(n)
      return "th"
    elsif last_number == 1
      return "st"
    elsif last_number == 2
      return "nd"
    elsif last_number == 3
      return "rd"
    else
      return "th"
    end
  end

  def sunday_on_or_before_date(date)
    date.sunday? ?
      date :
      sunday_on_or_before_date(date-1)
  end

  def saturday_on_or_after_date(date)
    date.saturday? ?
      date :
      saturday_on_or_after_date(date+1)
  end

end

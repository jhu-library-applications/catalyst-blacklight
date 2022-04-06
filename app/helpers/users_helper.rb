require 'tzinfo'

module UsersHelper

  # handle both Date's without a time, and Time's with hour/minute/second
  # appropriately.
  def relative_due_date(date_or_time)
    tz = TZInfo::Timezone.get('US/Eastern')
    offset_in_hours = (tz.current_period.observed_utc_offset / (60 * 60))
    offset = '%+.2d:00' % offset_in_hours
    date = Time.now.utc.getlocal(offset).to_date
    time = Time.now + offset_in_hours * 60 * 60

    if date_or_time.kind_of?(Time)
      distance_of_time_in_words(time, date_or_time)
    elsif date_or_time == date
      "today"
    elsif (date_or_time == (date + 1))
      "tomorrow"
    else
      distance_of_time_in_words(date, date_or_time)
    end
  end

end

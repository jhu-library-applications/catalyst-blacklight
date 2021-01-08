# date and time formats used by _holding.html.erb for due dates.
# Should we be using new style of i18n instead?

Date::DATE_FORMATS[:due_date] = "%b %e %Y"

Time::DATE_FORMATS[:due_date] = "%b %e %Y %I:%M %p"

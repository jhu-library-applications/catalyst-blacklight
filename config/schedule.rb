# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#

every :day, at: '2:00am' do
   rake 'nightly_cleanup'
end

every :hour do
   rake 'purge_guest_users'
end

# Learn more: http://github.com/javan/whenever

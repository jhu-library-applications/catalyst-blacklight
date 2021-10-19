# nightly maintenance tasks, rake nightly_cleanup is installed
# in cronfile (by capistrano with whenever), chain any tasks
# you need done nightly off of here in more rake pre-reqs like so...

desc 'Nightly db cleanup tasks for JH Catalyst'
task 'nightly_cleanup' => [:purge_searches]


desc 'purge old search data'
task 'purge_searches' => :environment do
  # We don't use saved searches anymore, but it is used
  # when paging through results on a show page

  # This is the most efficient way to delete all the searches
  begin
    ActiveRecord::Base.connection.execute('TRUNCATE searches')
    puts 'The searches table has been truncated.'
  rescue ActiveRecord::ConnectionNotEstablished
    puts 'There was a problem connecting to the database.'
  rescue StandardError
    puts 'An error occurred when truncating the searches table.'
  end
end

desc 'purge old guest user data'
task 'purge_guest_users' => :environment do
  # This removes guest users which accumulate in the 
  # the users table. 
  begin
    ActiveRecord::Base.connection.execute("DELETE FROM users WHERE users.login LIKE '%guest_user%' AND updated_at < NOW() - INTERVAL 1 DAY LIMIT 10000")
    puts 'The users table has been reduced in size.'
  rescue ActiveRecord::ConnectionNotEstablished
    puts 'There was a problem connecting to the database.'
  rescue StandardError
    puts 'An error occurred when cleaning the users table.'
  end
end

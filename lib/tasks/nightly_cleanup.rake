# nightly maintenance tasks, rake nightly_cleanup is installed
# in cronfile (by capistrano with whenever), chain any tasks
# you need done nightly off of here in more rake pre-reqs like so...

desc "Nightly db cleanup tasks for JH Catalyst"
task "nightly_cleanup" => [:purge_searches, :purge_guest_users]


desc "purge old search data"
task "purge_searches" => :environment do
  # BL comes with a task to delete old records from Searches table,
  # but it's a hot mess, using destroy_all instead of delete_all
  # (horrible idea on lots of rows), 7 days (too long), etc. 
  # we just redo it ourselves, sorry.
  puts "#{DateTime.now}: Purging searches more than 2 days old"    
  searches = Search.delete_all(['created_at < ? AND user_id IS NULL', DateTime.now - 2.days])  
  puts "   Purged #{searches} searches"
end

# For bookmarks with un-logged in users, BL wants us to create
# temporary guest users. We need to purge them, as well as any
# related data. 
desc "Purge old guest user data"
task "purge_guest_users" => :environment do
  days_old    = (ENV["GUEST_DAYS_OLD"] || 7).to_i.days
  older_than  = DateTime.now - days_old
  puts "#{DateTime.now}: Purging guest user data older than #{days_old.inspect} ago"

  # We're going to create the Arel for old guest users, then use
  # it to hand-construct DELETE's for bookmarks and searches
  # corresponding to those users using a sub-query. Before
  # deleting the users themselves too. 
  #
  # If we were in Rails4, we could do more natural deletes
  # with joins. 
  # http://stackoverflow.com/questions/4235838/rails-is-it-possible-to-delete-all-with-inner-join-conditions
  # https://github.com/rails/rails/issues/919  
  expired_guests = User.where(:guest => true).where(["created_at < ?", older_than])
  inner_query    = expired_guests.select("users.id")

  bookmarks = Bookmark.where(:user_id => inner_query).delete_all
  searches  = Search.where(:user_id => inner_query).delete_all
  users     = expired_guests.delete_all

  puts "   Purged #{bookmarks} bookmarks, #{searches} searches, and #{users} guest users."
end

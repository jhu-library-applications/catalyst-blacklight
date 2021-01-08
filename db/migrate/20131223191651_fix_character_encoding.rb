# Try to fix up charset and collation on our Blacklight MySQL tables,
# uses MySQL-specific SQL to set character set and collation on database
# and existing tables, and convert existing data we think too.
# Setting default on database should effect future
# tables.
#
# WARNING: hacky potentially dangerous code, use with care and at your own risk.
#
# WARNING: Will delete all Searches _without_ user_ids -- that is, will
# zero out current sessions search history, but should not delete actual
# saved searches.
#
# For saved searches, will try to delete invalid YAML `utf8: ?` keys from
# hash. Invalid because the ? needs to be quoted, but certain versions of
# certain gems with bad MySQL encoding produces that bad YAML. We delete the
# row entirely, we don't really need it.
#
# It's possible other bad YAML is still in there, we just delete this one
# common known case.
class FixCharacterEncoding < ActiveRecord::Migration[4.2]
  def up
    # Delete all searches that aren't saved searches -- search history for current
    # sessions will be reset, but we'll have fewer rows to deal with char encodings
    #Search.where(:user_id => nil).delete_all


    # Not sure what the difference between 'DEFAULT' charset/collation and without
    # default, do both just to be sure
    execute("ALTER DATABASE DEFAULT CHARACTER SET utf8 CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT COLLATE utf8_unicode_ci")


    # Now we have to fix it for each table too
    table_names = ActiveRecord::Base.connection.execute(
      "select table_name from information_schema.tables where table_schema = (select DATABASE())"
    ).collect {|r| r.first}
    table_names.each do |table_name|
      execute("ALTER TABLE #{table_name} CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;")
    end


    # Now we're going to go through all existing ones and fix the
    # query_params  "utf8: ?", which can't be read by some versions of ruby YAML.
    # Note there may be other unreadable query_params involved, we're just fixing
    # this one known common pattern.
    #
    # We're actually just gonna delete the utf8:? thing, it's probably
    # useless.

    puts "-- Removing `utf8: ?` from existing saved Searches"
    i = 0

    # as raw_query_params keeps it from de-serializing
    Search.select(["id", "query_params AS raw_query_params"]).find_each do |record|
      fixed_yaml = ""

      record.raw_query_params.lines.each do |line|
        unless line =~ /\A *\:?utf8\: *\? *\n\Z/
          fixed_yaml << line
        end
      end

      if fixed_yaml != record.raw_query_params
        i += 1
        puts "Fixing #{record.id}"
        Search.where(:id => record.id).update_all(:query_params => fixed_yaml)
      end
    end
    puts "   updated #{i} records to remove `utf8: ?`"
  end

  def down
    # Can't actually go down, but we're not gonna raise, it doesn't hardly matter,
    # plus our 'up' is idempotent.
    puts("WARNING: Can't undo migration FixCharacterEncoding entirely, but we'll change charsets back to latin1 i guess, this might not be a reverse if they werne't latin1 before!")

    execute("ALTER DATABASE DEFAULT CHARACTER SET latin1 CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT COLLATE latin1_swedish_ci")

    table_names = ActiveRecord::Base.connection.execute(
      "select table_name from information_schema.tables where table_schema = (select DATABASE())"
    ).collect {|r| r.first}
    table_names.each do |table_name|
      execute("ALTER TABLE #{table_name} CONVERT TO CHARACTER SET latin1 COLLATE latin1_swedish_ci;")
    end
  end
end

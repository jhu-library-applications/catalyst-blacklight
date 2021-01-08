# Because of the way we're deleting and recreating this data all the time,
# the mysql auto increment pks go ever up -- and we ran out of room, reaching
# max int.
#
# So changing pk to mysql bigint. Sorry, no way to do this with activerecord
# migration but raw sql.
#
# (TODO? Should we reset mysql auto_increment instead after load? That
#  might be better. although also would be mysql-specific with rails. )
#
class WidenReservesPks < ActiveRecord::Migration[4.2]
  def self.up
    execute('ALTER TABLE reserves_course_bibs MODIFY id bigint auto_increment')
    execute('ALTER TABLE reserves_course_instructors MODIFY id bigint auto_increment')
  end

  def self.down
    execute('ALTER TABLE reserves_course_bibs MODIFY id int auto_increment')
    execute('ALTER TABLE reserves_course_instructors MODIFY id int auto_increment')
  end
end

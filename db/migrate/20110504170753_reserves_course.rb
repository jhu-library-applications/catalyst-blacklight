class ReservesCourse < ActiveRecord::Migration[4.2]
  def self.up
    create_table :reserves_courses, :primary_key => :course_id  do |t|
      t.string :name, :null => false
      t.string :location_code
      t.string :location
      t.string :comment
      t.string :course_descr
      t.string :course_group_descr
    end
  end

  def self.down
    drop_table :reserves_courses
  end
end

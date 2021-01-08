class ReservesInstructors < ActiveRecord::Migration[4.2]
  def self.up
    create_table :reserves_course_instructors do |t|
      t.integer :reserves_course_id, :null => false
      t.string :instructor_str, :null => false
    end
    add_index :reserves_course_instructors, :reserves_course_id
  end

  def self.down
    remove_index :reserves_course_instructors, :reserves_course_id
    drop_table :reserves_course_instructors
  end
end

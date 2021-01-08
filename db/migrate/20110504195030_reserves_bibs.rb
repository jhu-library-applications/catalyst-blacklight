class ReservesBibs < ActiveRecord::Migration[4.2]
  def self.up
    create_table :reserves_course_bibs do |t|
      t.integer :reserves_course_id, :null => false
      t.integer :bib_id, :null => false
    end
    add_index :reserves_course_bibs, :reserves_course_id
  end

  def self.down
    remove_index :reserves_course_bibs, :reserves_course_id
    drop_table :reserves_course_bibs
  end
end

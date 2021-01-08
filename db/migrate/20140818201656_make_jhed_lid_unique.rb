class MakeJhedLidUnique < ActiveRecord::Migration[4.2]
  def change
    remove_index :users, :jhed_lid
    add_index :users, :jhed_lid, unique: true
  end
end

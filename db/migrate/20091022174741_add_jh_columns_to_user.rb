class AddJhColumnsToUser < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :hopkins_id, :string
    add_index :users, :hopkins_id

    add_column :users, :jhed_lid, :string
    add_index :users, :jhed_lid

    add_column :users, :horizon_borrower_id, :string
    add_index :users, :horizon_borrower_id

    add_column :users, :name, :string
  end

  def self.down
    remove_index :users, :hopkins_id
    remove_column :users, :hopkins_id

    remove_index :users, :jhed_lid
    remove_column :users, :jhed_lid


    remove_index :users, :horizon_borrower_id
    remove_column :users, :horizon_borrower_id

    remove_column :users, :name
  end
end

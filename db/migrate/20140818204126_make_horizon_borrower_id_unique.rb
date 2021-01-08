class MakeHorizonBorrowerIdUnique < ActiveRecord::Migration[4.2]
  def change
    remove_index :users, :horizon_borrower_id
    add_index :users, :horizon_borrower_id, unique: true
  end
end

class RemoveUserUniqueIndexes < ActiveRecord::Migration[4.2]
  # drop unique indexes on horizon_borrower_id and jhed_lid, JH identity management
  # is a mess, and it can happen, and best way is to handle it in code when it does,
  # not try to keep it from being inserted into db.
  def up
    remove_index "users", ["horizon_borrower_id"]
    remove_index "users", ["jhed_lid"]

    add_index "users", ["horizon_borrower_id"]
    add_index "users", ["jhed_lid"]
  end

  def down
    remove_index "users", ["horizon_borrower_id"], unique: true
    remove_index "users", ["jhed_lid"], unique: true
  end
end

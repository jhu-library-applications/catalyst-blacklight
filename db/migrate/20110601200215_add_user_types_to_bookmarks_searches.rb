class AddUserTypesToBookmarksSearches < ActiveRecord::Migration[4.2]
  def self.up
    # Set default values so after we've added the column, old
    # BL 2.x can keep using the same table, and if it inserts
    # rows they'll get the right 'user_type' so when we switch
    # to BL 3.x, it'll work with existing data.
    add_column :searches, :user_type, :string, :default => "User"
    add_column :bookmarks, :user_type, :string, :default => "User"
  end

  def self.down
    remove_column :searches, :user_type, :string
    remove_column :bookmarks, :user_type, :string
  end
end

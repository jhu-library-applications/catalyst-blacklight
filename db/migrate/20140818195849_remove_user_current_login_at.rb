class RemoveUserCurrentLoginAt < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :current_login_at, :datetime
  end
end

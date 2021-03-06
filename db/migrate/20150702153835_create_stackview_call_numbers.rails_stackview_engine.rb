# This migration comes from rails_stackview_engine (originally 20150602210254)
class CreateStackviewCallNumbers < ActiveRecord::Migration[4.2]
  def change
    create_table :stackview_call_numbers do |t|
      # these are what we want to assemble items in a sequence,
      t.string :sort_key, :null => false, :length => 200
      t.string :sort_key_display
      t.string :sort_key_type, :null => false, :length => 200

      # and be able to link back to external systems
      t.string :system_id, :null => false, :length => 100


      # These are what stackview wants or can use

      t.string :title, :null => false
      t.string :creator
      t.string :format

      t.integer    :measurement_page_numeric
      t.integer    :measurement_height_numeric
      t.integer    :shelfrank

      t.string :pub_date

      # pending true will not be included in results, can be
      # used for index updating strategies to avoid duplication.
      t.column :pending, :boolean, :default => false

      # record created_at for bookkeeping
      t.column :created_at, :datetime

      # indexes
      t.index :system_id
      t.index :sort_key
    end
  end
end

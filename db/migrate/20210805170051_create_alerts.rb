class CreateAlerts < ActiveRecord::Migration[5.2]
  def change
    create_table :alerts do |t|
      t.string "alert_type"
      t.string "level"
      t.string "title", null: true
      t.text "description", null: true
      t.string "url", null: true
      t.datetime "start_at", null: true
      t.datetime "end_at", null: true
    end
  end
end

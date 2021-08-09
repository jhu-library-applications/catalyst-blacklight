# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_08_05_170051) do

  create_table "alerts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "alert_type"
    t.string "level"
    t.string "title"
    t.text "description"
    t.string "url"
    t.datetime "start_at"
    t.datetime "end_at"
  end

  create_table "blacklight_folders_folder_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.bigint "folder_id", null: false
    t.bigint "bookmark_id", null: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bookmark_id"], name: "index_blacklight_folders_folder_items_on_bookmark_id"
    t.index ["folder_id"], name: "index_blacklight_folders_folder_items_on_folder_id"
  end

  create_table "blacklight_folders_folders", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "user_type", null: false
    t.bigint "user_id", null: false
    t.string "visibility"
    t.integer "number_of_members", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_type", "user_id"], name: "index_blacklight_folders_folders_on_user_type_and_user_id"
  end

  create_table "bookmarks", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "document_id"
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "user_type", default: "User"
    t.string "document_type"
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "flipper_features", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "reserves_course_bibs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "reserves_course_id", null: false
    t.integer "bib_id", null: false
    t.index ["reserves_course_id"], name: "index_reserves_course_bibs_on_reserves_course_id"
  end

  create_table "reserves_course_instructors", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "reserves_course_id", null: false
    t.string "instructor_str", null: false
    t.index ["reserves_course_id"], name: "index_reserves_course_instructors_on_reserves_course_id"
  end

  create_table "reserves_courses", primary_key: "course_id", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "location_code"
    t.string "location"
    t.string "comment"
    t.string "course_descr"
    t.string "course_group_descr"
  end

  create_table "searches", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.text "query_params"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "user_type", default: "User"
    t.index ["user_id"], name: "index_searches_on_user_id"
  end

  create_table "stackview_call_numbers", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "sort_key", null: false
    t.string "sort_key_display"
    t.string "sort_key_type", null: false
    t.string "system_id", null: false
    t.string "title", null: false
    t.string "creator"
    t.string "format"
    t.integer "measurement_page_numeric"
    t.integer "measurement_height_numeric"
    t.integer "shelfrank"
    t.string "pub_date"
    t.boolean "pending", default: false
    t.datetime "created_at"
    t.index ["sort_key"], name: "index_stackview_call_numbers_on_sort_key"
    t.index ["system_id"], name: "index_stackview_call_numbers_on_system_id"
  end

  create_table "taggings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "tag_id"
    t.integer "taggable_id"
    t.string "taggable_type"
    t.datetime "created_at"
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type"], name: "index_taggings_on_taggable_id_and_taggable_type"
  end

  create_table "tags", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
  end

  create_table "users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "login", null: false
    t.string "email"
    t.string "crypted_password"
    t.text "last_search_url"
    t.datetime "last_login_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "password_salt"
    t.string "persistence_token"
    t.string "hopkins_id"
    t.string "jhed_lid"
    t.string "horizon_borrower_id"
    t.string "name"
    t.boolean "guest", default: false
    t.index ["hopkins_id"], name: "index_users_on_hopkins_id"
    t.index ["horizon_borrower_id"], name: "index_users_on_horizon_borrower_id"
    t.index ["jhed_lid"], name: "index_users_on_jhed_lid"
  end

end

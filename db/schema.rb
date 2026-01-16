# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_16_060027) do
  create_table "items", force: :cascade do |t|
    t.integer "amount"
    t.string "catalog_no"
    t.datetime "created_at", null: false
    t.integer "difference_actual"
    t.integer "inner_box_count"
    t.integer "lower_price"
    t.string "package"
    t.string "page"
    t.string "product_cd"
    t.string "product_name"
    t.integer "quantity"
    t.integer "quote_id", null: false
    t.decimal "rate", precision: 5, scale: 2
    t.string "row"
    t.integer "special_upper_price"
    t.datetime "updated_at", null: false
    t.integer "upper_price"
    t.index ["quote_id"], name: "index_items_on_quote_id"
  end

  create_table "quotes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "created_on"
    t.string "customer_code"
    t.string "customer_name"
    t.string "kintone_record_id"
    t.integer "kintone_revision"
    t.text "note"
    t.integer "rate_common"
    t.integer "rate_essence"
    t.integer "rate_f_symbol"
    t.integer "rate_h_symbol"
    t.integer "rate_kurashino"
    t.integer "rate_porcelains"
    t.integer "rate_proper"
    t.text "raw_payload"
    t.string "ship_to_name"
    t.string "staff_code"
    t.string "staff_name"
    t.string "status", default: "pending", null: false
    t.string "stock_status", default: "secured", null: false
    t.integer "subtotal", default: 0, null: false
    t.datetime "synced_at"
    t.datetime "updated_at", null: false
    t.index ["created_on"], name: "index_quotes_on_created_on"
    t.index ["kintone_record_id"], name: "index_quotes_on_kintone_record_id"
    t.index ["status"], name: "index_quotes_on_status"
  end

  add_foreign_key "items", "quotes"
end

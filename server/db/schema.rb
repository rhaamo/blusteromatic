# encoding: UTF-8
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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121227165800) do

  create_table "jobs", :force => true do |t|
    t.string   "name"
    t.string   "status"
    t.string   "node_status"
    t.integer  "user_id"
    t.string   "filename"
    t.string   "job_name"
    t.integer  "node_id"
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
    t.string   "render_type",        :default => "SINGLE"
    t.integer  "render_frame_start", :default => 0
    t.integer  "render_frame_stop",  :default => 0
    t.string   "render_engine",      :default => "CYCLES"
    t.integer  "priority",           :default => 0
    t.string   "slug"
    t.string   "dot_blend"
  end

  add_index "jobs", ["slug"], :name => "index_jobs_on_slug", :unique => true

  create_table "nodes", :force => true do |t|
    t.string   "name",                           :null => false
    t.string   "os",                             :null => false
    t.string   "blender_engines",                :null => false
    t.string   "uuid",                           :null => false
    t.datetime "last_ping"
    t.string   "blender_version",                :null => false
    t.integer  "validated",       :default => 0, :null => false
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.string   "slug"
  end

  add_index "nodes", ["slug"], :name => "index_nodes_on_slug", :unique => true

  create_table "users", :force => true do |t|
    t.string   "email",                                 :default => "", :null => false
    t.string   "encrypted_password",                    :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                         :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "authentication_token"
    t.datetime "created_at",                                            :null => false
    t.datetime "updated_at",                                            :null => false
    t.string   "login",                  :limit => nil
    t.string   "slug"
  end

  add_index "users", ["authentication_token"], :name => "index_users_on_authentication_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["slug"], :name => "index_users_on_slug", :unique => true

end

class AddFriendlyIdStuff < ActiveRecord::Migration
  def change
    add_column :users, :slug, :string, :unique => true
    add_column :nodes, :slug, :string, :unique => true
    add_column :jobs, :slug, :string, :unique => true

    add_index :users, :slug, unique: true
    add_index :nodes, :slug, unique: true
    add_index :jobs, :slug, unique: true
  end
end

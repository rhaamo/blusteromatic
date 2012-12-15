class AddLoginToUsers < ActiveRecord::Migration
  def change
    add_column :users, :login, :varchar
  end
end

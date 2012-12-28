class AddMd5ToJob < ActiveRecord::Migration
  def change
    add_column :jobs, :md5, :string
  end
end

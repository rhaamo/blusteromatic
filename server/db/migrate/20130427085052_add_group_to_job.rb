class AddGroupToJob < ActiveRecord::Migration
  def change
    add_column :jobs, :group, :integer
  end
end

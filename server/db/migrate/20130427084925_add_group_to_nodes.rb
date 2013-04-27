class AddGroupToNodes < ActiveRecord::Migration
  def change
    add_column :nodes, :group, :integer
  end
end

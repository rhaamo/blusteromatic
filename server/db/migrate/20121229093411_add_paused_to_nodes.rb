class AddPausedToNodes < ActiveRecord::Migration
  def change
    add_column :nodes, :paused, :integer, :default => 0
  end
end

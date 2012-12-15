class AddDefaultValueForJobPriority < ActiveRecord::Migration
  def change
    remove_column :jobs, :priority
    add_column :jobs, :priority, :integer, :default => 0
  end
end

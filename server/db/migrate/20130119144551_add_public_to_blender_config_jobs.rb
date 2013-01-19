class AddPublicToBlenderConfigJobs < ActiveRecord::Migration
  def change
    add_column :blender_configs, :public, :boolean, :default => 0
  end
end

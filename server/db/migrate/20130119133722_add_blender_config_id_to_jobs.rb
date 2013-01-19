class AddBlenderConfigIdToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :blender_config_id, :integer
  end
end

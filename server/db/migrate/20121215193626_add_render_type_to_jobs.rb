class AddRenderTypeToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :render_type, :string, :default => "SINGLE" # SINGLE / FRAME
    add_column :jobs, :render_frame_start, :integer, :default => 0
    add_column :jobs, :render_frame_stop, :integer, :default => 0
  end
end

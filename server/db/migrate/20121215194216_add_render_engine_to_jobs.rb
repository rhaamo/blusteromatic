class AddRenderEngineToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :render_engine, :string, :default => "CYCLES" #
  end
end

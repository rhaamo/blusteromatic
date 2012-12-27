class AddDotBlendToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :dot_blend, :string
  end
end

class AddComputeToNodes < ActiveRecord::Migration
  def change
    add_column :nodes, :compute, :string, :default => "CPU"
  end
end

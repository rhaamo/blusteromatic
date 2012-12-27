class AddComputeToJob < ActiveRecord::Migration
  def change
    add_column :jobs, :compute, :string, :default => 'CPU'
  end
end

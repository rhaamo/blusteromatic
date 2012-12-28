class AddConsoleLogsToJob < ActiveRecord::Migration
  def change
    add_column :jobs, :log, :text
  end
end

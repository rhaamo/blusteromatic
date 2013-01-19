class AddConsoleLogToRenders < ActiveRecord::Migration
  def change
    add_column :renders, :console_log, :text
  end
end

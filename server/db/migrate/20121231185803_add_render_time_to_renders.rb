class AddRenderTimeToRenders < ActiveRecord::Migration
  def change
    add_column :renders, :render_time, :string
  end
end

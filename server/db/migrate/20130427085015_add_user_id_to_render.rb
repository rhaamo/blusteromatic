class AddUserIdToRender < ActiveRecord::Migration
  def change
    add_column :renders, :user_id, :integer
  end
end

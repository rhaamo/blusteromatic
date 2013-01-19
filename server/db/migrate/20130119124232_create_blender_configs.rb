class CreateBlenderConfigs < ActiveRecord::Migration
  def change
    create_table :blender_configs do |t|
      t.string :name
      t.text :description
      t.text :config
      t.string :slug

      t.integer :user_id
      t.timestamps
    end
  end
end

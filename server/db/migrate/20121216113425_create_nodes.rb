class CreateNodes < ActiveRecord::Migration
  def change
    create_table :nodes do |t|
      t.string :name, :null => false
      t.string :os, :null => false
      t.string :blender_engines, :null => false
      t.string :uuid, :null => false
      t.datetime :last_ping
      t.string :blender_version, :null => false

      t.integer :validated, :null => false, :default => 0 # 0 = no, 1 = yes, nil = refused

      t.timestamps
    end
  end
end

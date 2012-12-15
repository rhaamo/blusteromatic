class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.string :name
      t.integer :priority
      t.string :status
      t.string :node_status
      t.integer :user_id
      t.string :filename
      t.string :job_name
      t.integer :node_id

      t.timestamps
    end
  end
end

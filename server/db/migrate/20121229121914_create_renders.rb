class CreateRenders < ActiveRecord::Migration
  def change
    create_table :renders do |t|
      t.string :filename
      t.string :output
      t.integer :job_id

      t.timestamps
    end
  end
end

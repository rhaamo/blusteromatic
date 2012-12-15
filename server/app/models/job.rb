class Job < ActiveRecord::Base
  attr_accessible :filename, :job_name, :name, :node_id, :node_status, :priority, :status, :user_id
end

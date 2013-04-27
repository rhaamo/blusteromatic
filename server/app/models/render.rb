class Render < ActiveRecord::Base
  attr_accessible :filename, :output, :job_id, :console_log
  belongs_to :job
  belongs_to :user
  mount_uploader :output, RenderFileUploader
end

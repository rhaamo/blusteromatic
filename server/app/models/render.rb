class Render < ActiveRecord::Base
  attr_accessible :filename, :output, :job_id
  belongs_to :job
  mount_uploader :output, RenderFileUploader
end

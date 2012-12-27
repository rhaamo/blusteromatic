class Job < ActiveRecord::Base
  attr_accessible :filename, :job_name, :name, :node_id, :node_status, :priority, :status, :user_id, :render_type, :render_frame_start, :render_frame_stop, :render_engine, :dot_blend, :compute, :dot_blend_cache

  extend FriendlyId
  friendly_id :name, use: :slugged

  # job_name : "name(sanitized)_render_type_start_stop_engine" like "my_job_01_ANIM_0_150_CYCLES"

  belongs_to :user
  belongs_to :node

  mount_uploader :dot_blend, DotBlendUploader

  validates_presence_of :dot_blend, :render_engine, :render_frame_stop, :render_frame_start, :render_type, :priority, :name

end

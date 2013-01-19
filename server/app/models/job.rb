class Job < ActiveRecord::Base
  attr_accessible :filename, :job_name, :name, :node_id, :node_status, :priority, :status, :user_id, :render_type, :render_frame_start, :render_frame_stop, :render_engine, :dot_blend, :compute, :dot_blend_cache, :blender_config_id

  extend FriendlyId
  friendly_id :name, use: :slugged

  # job_name : "name(sanitized)_render_type_start_stop_engine" like "my_job_01_ANIM_0_150_CYCLES"

  belongs_to :user
  belongs_to :node
  has_many :renders
  belongs_to :blender_config

  mount_uploader :dot_blend, DotBlendUploader

  validates_presence_of :dot_blend, :render_engine, :render_frame_stop, :render_frame_start, :render_type, :priority, :name, :blender_config_id
  before_validation :compute_hash
  before_save :save_filename
  before_create :default_status

  def compute_hash
    self.md5 = Digest::MD5.hexdigest(self.dot_blend.read)
  end
  def save_filename
    self.filename = self.dot_blend.file.filename
  end
  def default_status
    self.status = "waiting"
    self.node_status = "waiting"
  end
end

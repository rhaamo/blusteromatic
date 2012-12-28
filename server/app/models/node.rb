class Node < ActiveRecord::Base
  attr_accessible :os, :blender_engines, :uuid, :blender_version, :name, :validated, :last_ping, :compute

  extend FriendlyId
  friendly_id :name, use: :slugged

  has_many :jobs

  def alive?
     Time.now - self.last_ping < 1.hour
  end
end

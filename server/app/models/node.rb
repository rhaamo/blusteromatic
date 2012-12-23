class Node < ActiveRecord::Base
  attr_accessible :os, :blender_engines, :uuid, :blender_version, :name, :validated, :last_ping

  extend FriendlyId
  friendly_id :name, use: :slugged

  has_many :jobs
end

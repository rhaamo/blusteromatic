class BlenderConfig < ActiveRecord::Base
  # attr_accessible :title, :body
  attr_accessible :name, :description, :config, :public, :user_id

  extend FriendlyId
  friendly_id :name, use: :slugged

  belongs_to :user
  belongs_to :job

  validates_presence_of :name, :config

end

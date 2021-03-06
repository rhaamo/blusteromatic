class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :login, :email, :password, :password_confirmation, :remember_me, :role

  extend FriendlyId
  friendly_id :login, use: :slugged

  has_many :jobs
  has_many :renders
  
  def admin?
    self.role >= Group.get_id(:admin)
  end

end

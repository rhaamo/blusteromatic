class Ability
  include CanCan::Ability

  def user_default(user)
    can :manage, User, :id => user.id
    can :read, User

    can :use, Node, :group => Group.get_id(:public)
    can :read, Node, :group => Group.get_id(:public)

    can :manage, Job, :user_id => user.id
    can :manage, Render, :user_id => user.id

    can :read, Job, :group => Group.get_id(:public)
  end

  def user_event(user)
    can :use, Node, :group => Group.get_id(:event)
    can :read, Node, :group => Group.get_id(:event)
  end

  def user_admin(user)
    can :manage, :all
  end

  def initialize(user)
    user ||= User.new # guest user

    if user.role == nil
        user.role = 0
    end

    if !user.role or user.new_record?
        user_default(user)
    else
        user_default(user)
        user_event(user) if user.role >= 1
        user_admin(user) if user.role >= 12
    end
  end
end

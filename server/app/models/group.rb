class Group < ActiveRecord::Base
  # Fake model DONT ... EVENT ... TOUCH ... IT !

  RAW_GROUPS = {
    0  => :default,
    1  => :event,
    4  => :public,
    8  => :private,
    12 => :admin
  }

  def self.users
    [0, 1, 12]
  end

  def self.jobs
    [1, 8]
  end

  def self.nodes
    [1, 4, 12]
  end


  def self.all
    RAW_GROUPS
  end

  def self.get_id(from_sym)
    RAW_GROUPS.key from_sym
  end

  def self.get_sym(from_id)
    RAW_GROUPS[from_id]
  end

end

class Node < ActiveRecord::Base
  attr_accessible :os, :blender_engines, :uuid, :blender_version, :name, :validated, :last_ping, :compute

  # Can be edited by admin : validated, paused and Group relations

  extend FriendlyId
  friendly_id :name, use: :slugged

  has_many :jobs

  scope :activated, { :conditions => ['validated = ?', 1] }

  def alive?
     Time.now - self.last_ping < 1.hour
  end

  def self.blender_engines(form=nil)
    all_be = self.activated.map(&:blender_engines)
    f_all_be = []
    all_be.map {|c| c.split(",").map {|d| f_all_be << d if !f_all_be.include? d}} if !form
    all_be.map {|c| c.split(",").map {|d| f_all_be << [d,d] if !f_all_be.include? d}} if form
    f_all_be
  end

  def self.computes(form=nil)
    all_c = self.activated.map(&:compute)
    f_all_c = []
    all_c.map {|c| c.split(",").map {|d| f_all_c << d if !f_all_c.include? d}} if !form
    all_c.map {|c| c.split(",").map {|d| f_all_c << [d,d] if !f_all_c.include? d}} if form
    f_all_c
  end
end

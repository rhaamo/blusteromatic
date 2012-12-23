class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :authenticate_user!, :only => :index

  def index
    @jobs = Job.all
    @nodes = Node.all
  end
end

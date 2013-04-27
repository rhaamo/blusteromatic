class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :authenticate_user!, :only => :index
  check_authorization :unless => :ohai_can_you_please_check_if_the_controller_name_is_application_kthxbye?

  def index
    @jobs = Job.accessible_by(current_ability)
    @nodes = Node.accessible_by(current_ability)
  end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  private
  def ohai_can_you_please_check_if_the_controller_name_is_application_kthxbye?
    if devise_controller?
      return true
    else
      controller_name == "application"
    end
  end
end

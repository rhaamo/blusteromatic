class ApplicationController < ActionController::Base
  protect_from_forgery
  check_authorization :unless => :ohai_can_you_please_check_if_the_controller_name_is_application_kthxbye?


  def index
    @jobs = Job.accessible_by(current_ability)
    @nodes = Node.accessible_by(current_ability)

    if current_user
      render 'index'
    else
      render 'jobs/_list'
    end
  end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  private
  def ohai_can_you_please_check_if_the_controller_name_is_application_kthxbye?
    return true if controller_path.start_with?("api/")
    if devise_controller?
      return true
    else
      controller_name == "application"
    end
  end
end

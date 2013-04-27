class ApplicationController < ActionController::Base
  protect_from_forgery
  check_authorization :unless => :ohai_can_you_please_check_if_the_controller_name_is_application_kthxbye?

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

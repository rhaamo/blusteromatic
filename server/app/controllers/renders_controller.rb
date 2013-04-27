class RendersController < ApplicationController
  load_and_authorize_resource
  def index
    @job = Job.find(params[:job_id])
    authorize! :show, @job
  end
end

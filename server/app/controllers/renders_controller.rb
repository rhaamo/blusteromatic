class RendersController < ApplicationController
  before_filter :authenticate_user!

  def index
    @job = Job.find(params[:job_id])
    @renders = @job.renders
  end

  def show
    @job = Job.find(params[:job_id])
    @render = Render.find(params[:id])
  end

end

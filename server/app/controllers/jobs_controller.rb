class JobsController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource

  # GET /jobs
  # GET /jobs.json
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @jobs }
    end
  end

  # GET /jobs/1
  # GET /jobs/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @job }
    end
  end

  # GET /jobs/new
  # GET /jobs/new.json
  def new
    @job = Job.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @job }
    end
  end

  # GET /jobs/1/edit
  def edit
  end

  # POST /jobs
  # POST /jobs.json
  def create
    @job = Job.new(params[:job])

    @job.user = current_user

    respond_to do |format|
      if @job.save
        format.html { redirect_to @job, notice: 'Job was successfully created.' }
        format.json { render json: @job, status: :created, location: @job }
      else
        format.html { render action: "new" }
        format.json { render json: @job.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /jobs/1
  # PUT /jobs/1.json
  def update
    respond_to do |format|
      if @job.update_attributes(params[:job])
        format.html { redirect_to @job, notice: 'Job was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @job.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /jobs/1
  # DELETE /jobs/1.json
  def destroy
    @job.destroy

    respond_to do |format|
      format.html { redirect_to jobs_url }
      format.json { head :no_content }
    end
  end

  def reassign
    # We just call assign, but we reset statues before that
    @job = Job.find(params[:job_id])
    @job.default_status
    @job.save
    assign
  end

  def assign
    @job = Job.find(params[:job_id])
    # find a node compatible with this kind of caracteristics : CPU or GPU, RENDER_ENGINE
    the_node = nil
    Node.where(:validated => true).each do |node|
      # Skip inactive and not alive nodes
      next if !node.alive?
      # Skip not matching blender engine
      next if !node.blender_engines.split(",").include? @job.render_engine
      # Skip not matching compute capabilities
      next if !node.compute.split(",").include? @job.compute
      # If we are here, the node match all points \o/
      the_node = node
      break
    end

    if the_node
      @job.node = the_node
      @job.save
      redirect_to @job, :notice => "Job assigned to #{the_node.name}."
    else
      redirect_to root_url, :notice => "Can't find active node with #{@job.render_engine},#{@job.compute} capabilities."
    end
  end

  def reset
    @job = Job.find(params[:job_id])
    @job.default_status
    @job.node = nil
    @job.save
    redirect_to @job
  end

end

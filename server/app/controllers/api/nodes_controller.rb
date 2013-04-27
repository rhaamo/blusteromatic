class Api::NodesController < ApplicationController
  before_filter :restrict_access
  respond_to :json

  def heartbeat
    # Got heartbeat, infos available : version, engines, os, hostname, uuid
    node = Node.find_or_create_by_uuid(
                                       :os => params[:os],
                                       :blender_engines => params[:engines],
                                       :uuid => params[:uuid],
                                       :blender_version => params[:version],
                                       :name => params[:hostname],
                                       :compute => params[:compute]
                                       )
    # Workaround for update_or_create which doesn't seems to exist !
    node.last_ping = Time.now
    node.blender_engines = params[:engines]
    node.blender_version = params[:version]
    node.name = params[:hostname]
    node.compute = params[:compute]
    node.save
    hash = {:validated => node.validated, :id => node.id, :paused => node.paused}
    render :json => hash.to_json
  end

  def get_job
    # Got job request, infos available : compute, uuid
    node = Node.find_by_uuid(params[:uuid])
    job = Job.find_by_node_id_and_compute_and_status(node.id, params[:compute], "waiting")

    if !job
      job = {:error => "No jobs available"}
      return render :json => job.to_json
    end

    render :json => {:job => job, :config => job.blender_config}.to_json
  end

  def update_job
    # Got job update, infos available : uuid, job ID, console_log, :job_status, :node_status
    node = Node.find_by_uuid(params[:uuid])
    job = Job.find_by_node_id_and_id(node.id, params[:job_id])
    job.log = params[:console_log]
    job.status = params[:job_status]
    job.node_status = params[:node_status]
    job.save
    render :json => {:status => 'ok'}
  end

  def finish_job
    # Got job finish, infos available : uuid, job ID, console_log, filename, file render
    node = Node.find_by_uuid(params[:uuid])
    job = Job.find_by_node_id_and_id(node.id, params[:job_id])
    job.log = params[:console_log]
    job.status = "finished"
    job.node_status = "rendered"

    r = Render.new
    r.job_id = job.id
    r.filename = params[:filename]
    r.output = params[:output_file]
    r.render_time = params[:render_time]
    r.console_log = params[:console_log]
    r.user_id = job.user_id
    
    r.save
    job.save
    render :json => {:status => 'ok'}
  end

  def error_job
    # Got job error, just put node_status as error, and status as finished
    node = Node.find_by_uuid(params[:uuid])
    job = Job.find_by_node_id_and_id(node.id, params[:job_id])
    job.log = params[:console_log] if params[:console_log]
    job.status = "finished"
    job.node_status = "error"
    job.save
    render :json => {:status => 'ok'}
  end

  private
  def restrict_access
    api_key = (Settings.api_token == params[:access_token])
    head :unauthorized unless api_key
  end

end

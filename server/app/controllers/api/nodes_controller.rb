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
      hash = {:validated => node.validated, :id => node.id}
      render :json => hash.to_json
    end

    def get_jobs
    end

    def assign_job
    end

    def update_job
    end

    def finish_job
    end

    private
    def restrict_access
      api_key = (Settings.api_token == params[:access_token])
      head :unauthorized unless api_key
    end

  end

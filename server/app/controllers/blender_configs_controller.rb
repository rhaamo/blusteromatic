class BlenderConfigsController < ApplicationController
  # GET /blender_configs
  # GET /blender_configs.json
  def index
    @blender_configs = BlenderConfig.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @blender_configs }
    end
  end

  # GET /blender_configs/1
  # GET /blender_configs/1.json
  def show
    @blender_config = BlenderConfig.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @blender_config }
    end
  end

  # GET /blender_configs/new
  # GET /blender_configs/new.json
  def new
    @blender_config = BlenderConfig.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @blender_config }
    end
  end

  def clone
    @blender_config = BlenderConfig.new
    clone = BlenderConfig.find(params[:blender_config_id])
    @blender_config.name = clone.name
    @blender_config.description = clone.description
    @blender_config.config = clone.config

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @blender_config }
    end
  end

  # GET /blender_configs/1/edit
  def edit
    @blender_config = BlenderConfig.find(params[:id])
  end

  # POST /blender_configs
  # POST /blender_configs.json
  def create
    @blender_config = BlenderConfig.new(params[:blender_config])

    respond_to do |format|
      if @blender_config.save
        format.html { redirect_to @blender_config, notice: 'Blender config was successfully created.' }
        format.json { render json: @blender_config, status: :created, location: @blender_config }
      else
        format.html { render action: "new" }
        format.json { render json: @blender_config.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /blender_configs/1
  # PUT /blender_configs/1.json
  def update
    @blender_config = BlenderConfig.find(params[:id])

    respond_to do |format|
      if @blender_config.update_attributes(params[:blender_config])
        format.html { redirect_to @blender_config, notice: 'Blender config was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @blender_config.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /blender_configs/1
  # DELETE /blender_configs/1.json
  def destroy
    @blender_config = BlenderConfig.find(params[:id])
    @blender_config.destroy

    respond_to do |format|
      format.html { redirect_to blender_configs_url }
      format.json { head :no_content }
    end
  end
end

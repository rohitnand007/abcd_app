class UserDeviceConfigurationsController < ApplicationController
  authorize_resource #:only=>[:edit, :index, :new, :show]
  # GET /user_device_configurations
  # GET /user_device_configurations.json
  def index
    @user_device_configurations = UserDeviceConfiguration.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @user_device_configurations }
    end
  end

  # GET /user_device_configurations/1
  # GET /user_device_configurations/1.json
  def show
    @user_device_configuration = UserDeviceConfiguration.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @user_device_configuration }
    end
  end

  # GET /user_device_configurations/new
  # GET /user_device_configurations/new.json
  def new
    @user_device_configuration = UserDeviceConfiguration.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @user_device_configuration }
    end
  end

  # GET /user_device_configurations/1/edit
  def edit
    @user_device_configuration = UserDeviceConfiguration.find(params[:id])
  end

  # POST /user_device_configurations
  # POST /user_device_configurations.json
  def create
    @user_device_configuration = UserDeviceConfiguration.new(params[:user_device_configuration])

    respond_to do |format|
      if @user_device_configuration.save
        format.html { redirect_to @user_device_configuration, notice: 'User device configuration was successfully created.' }
        format.json { render json: @user_device_configuration, status: :created, location: @user_device_configuration }
      else
        format.html { render action: "new" }
        format.json { render json: @user_device_configuration.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /user_device_configurations/1
  # PUT /user_device_configurations/1.json
  def update
    @user_device_configuration = UserDeviceConfiguration.find(params[:id])

    respond_to do |format|
      if @user_device_configuration.update_attributes(params[:user_device_configuration])
        format.html { redirect_to @user_device_configuration, notice: 'User device configuration was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @user_device_configuration.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /user_device_configurations/1
  # DELETE /user_device_configurations/1.json
  def destroy
    @user_device_configuration = UserDeviceConfiguration.find(params[:id])
    @user_device_configuration.destroy

    respond_to do |format|
      format.html { redirect_to user_device_configurations_url }
      format.json { head :ok }
    end
  end
end

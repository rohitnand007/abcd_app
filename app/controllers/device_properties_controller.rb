class DevicePropertiesController < ApplicationController
  # GET /device_properties
  # GET /device_properties.json
  authorize_resource :only=>[:edit, :index, :new, :show]
  def index
    @device_properties = DeviceProperty.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @device_properties }
    end
  end

  # GET /device_properties/1
  # GET /device_properties/1.json
  def show
    @device_property = DeviceProperty.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @device_property }
    end
  end

  # GET /device_properties/new
  # GET /device_properties/new.json
  def new
    @device_property = DeviceProperty.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @device_property }
    end
  end

  # GET /device_properties/1/edit
  def edit
    @device_property = DeviceProperty.find(params[:id])
  end

  # POST /device_properties
  # POST /device_properties.json
  def create
    @device_property = DeviceProperty.new(params[:device_property])

    respond_to do |format|
      if @device_property.save
        format.html { redirect_to @device_property, notice: 'Device property was successfully created.' }
        format.json { render json: @device_property, status: :created, location: @device_property }
      else
        format.html { render action: "new" }
        format.json { render json: @device_property.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /device_properties/1
  # PUT /device_properties/1.json
  def update
    @device_property = DeviceProperty.find(params[:id])

    respond_to do |format|
      if @device_property.update_attributes(params[:device_property])
        format.html { redirect_to @device_property, notice: 'Device property was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @device_property.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /device_properties/1
  # DELETE /device_properties/1.json
  def destroy
    @device_property = DeviceProperty.find(params[:id])
    @device_property.destroy

    respond_to do |format|
      format.html { redirect_to device_properties_url }
      format.json { head :ok }
    end
  end
end

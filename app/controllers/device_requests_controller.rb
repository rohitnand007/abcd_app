class DeviceRequestsController < ApplicationController
  authorize_resource :only=>[:edit, :index, :new, :show]
  # GET /device_requests
  # GET /device_requests.json
  before_filter:must_be_admin
  def index
    @device_requests = DeviceRequest.order("id DESC").page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @device_requests }
    end
  end

  # GET /device_requests/1
  # GET /device_requests/1.json
  def show
    @device_request = DeviceRequest.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @device_request }
    end
  end

  # GET /device_requests/new
  # GET /device_requests/new.json
  def new
    @device_request = DeviceRequest.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @device_request }
    end
  end

  # GET /device_requests/1/edit
  def edit
    @device_request = DeviceRequest.find(params[:id])
  end

  # POST /device_requests
  # POST /device_requests.json
  def create
    @device_request = DeviceRequest.new(params[:device_request])

    respond_to do |format|
      if @device_request.save
        format.html { redirect_to @device_request, notice: 'Device request was successfully created.' }
        format.json { render json: @device_request, status: :created, location: @device_request }
      else
        format.html { render action: "new" }
        format.json { render json: @device_request.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /device_requests/1
  # PUT /device_requests/1.json
  def update
    @device_request = DeviceRequest.find(params[:id])

    respond_to do |format|
      if @device_request.update_attributes(params[:device_request])
        format.html { redirect_to @device_request, notice: 'Device request was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @device_request.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /device_requests/1
  # DELETE /device_requests/1.json
  def destroy
    @device_request = DeviceRequest.find(params[:id])
    @device_request.destroy

    respond_to do |format|
      format.html { redirect_to device_requests_url }
      format.json { head :ok }
    end
  end
end

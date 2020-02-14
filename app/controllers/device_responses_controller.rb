class DeviceResponsesController < ApplicationController
  authorize_resource :only=>[:edit, :index, :new, :show, :show1]
  # GET /device_responses
  # GET /device_responses.json
  before_filter:must_be_admin
  def index
    @device_responses = DeviceResponse.order("id DESC")

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @device_responses }
    end
  end

  # GET /device_responses/1
  # GET /device_responses/1.json
  def show
    @device_response = DeviceResponse.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @device_response }
    end
  end

  # GET /device_responses/1
  # GET /device_responses/1.json
  def show1
    @device_response = DeviceResponse.where(:request_id=>params[:request_id]).first

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @device_response }
    end
  end

  # GET /device_responses/new
  # GET /device_responses/new.json
  def new
    @device_response = DeviceResponse.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @device_response }
    end
  end

  # GET /device_responses/1/edit
  def edit
    @device_response = DeviceResponse.find(params[:id])
  end

  # POST /device_responses
  # POST /device_responses.json
  def create
    @device_response = DeviceResponse.new(params[:device_response])

    respond_to do |format|
      if @device_response.save
        format.html { redirect_to @device_response, notice: 'Device response was successfully created.' }
        format.json { render json: @device_response, status: :created, location: @device_response }
      else
        format.html { render action: "new" }
        format.json { render json: @device_response.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /device_responses/1
  # PUT /device_responses/1.json
  def update
    @device_response = DeviceResponse.find(params[:id])

    respond_to do |format|
      if @device_response.update_attributes(params[:device_response])
        format.html { redirect_to @device_response, notice: 'Device response was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @device_response.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /device_responses/1
  # DELETE /device_responses/1.json
  def destroy
    @device_response = DeviceResponse.find(params[:id])
    @device_response.destroy

    respond_to do |format|
      format.html { redirect_to device_responses_url }
      format.json { head :ok }
    end
  end
end

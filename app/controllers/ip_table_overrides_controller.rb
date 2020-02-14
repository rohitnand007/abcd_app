# For access to everything enter '*' in domain column
# For access to full domain enter '*.google.com' in domain column
class IpTableOverridesController < ApplicationController
  authorize_resource :only=>[:edit, :index, :new, :show]
#authorize_resource
  # GET /ip_table_overrides
  # GET /ip_table_overrides.json
  def index
    @ip_table_overrides = IpTableOverride.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @ip_table_overrides }
    end
  end

  # GET /ip_table_overrides/1
  # GET /ip_table_overrides/1.json
  def show
    @ip_table_override = IpTableOverride.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @ip_table_override }
    end
  end

  # GET /ip_table_overrides/new
  # GET /ip_table_overrides/new.json
  def new
    @ip_table_override = IpTableOverride.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @ip_table_override }
    end
  end

  # GET /ip_table_overrides/1/edit
  def edit
    @ip_table_override = IpTableOverride.find(params[:id])
  end

  # POST /ip_table_overrides
  # POST /ip_table_overrides.json
  def create
    @ip_table_override = IpTableOverride.new(params[:ip_table_override])

    respond_to do |format|
      if @ip_table_override.save
        format.html { redirect_to @ip_table_override, notice: 'Ip table override was successfully created.' }
        format.json { render json: @ip_table_override, status: :created, location: @ip_table_override }
      else
        format.html { render action: "new" }
        format.json { render json: @ip_table_override.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /ip_table_overrides/1
  # PUT /ip_table_overrides/1.json
  def update
    @ip_table_override = IpTableOverride.find(params[:id])

    respond_to do |format|
      if @ip_table_override.update_attributes(params[:ip_table_override])
        format.html { redirect_to @ip_table_override, notice: 'Ip table override was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @ip_table_override.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ip_table_overrides/1
  # DELETE /ip_table_overrides/1.json
  def destroy
    @ip_table_override = IpTableOverride.find(params[:id])
    @ip_table_override.destroy

    respond_to do |format|
      format.html { redirect_to ip_table_overrides_url }
      format.json { head :ok }
    end
  end
end
